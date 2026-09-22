/**
 * The basket (`/api/shop/cart`) and the quote → checkout → pay flow on top of it.
 *
 * One line per product AND colourway — the hex string is the variant id the cart takes,
 * so the same piece in another glaze is another line. The cart is not a reservation: every
 * fetch re-reads `line.in_stock` / `available_stock`, and checkout is blocked while any
 * line cannot be fulfilled. Lines are kept through checkout — the server empties the cart
 * only when the order is paid (or settled on creation), so that is when we refetch.
 */
export const HARD_MAX_QUANTITY = 100;

export const lineMax = (line) =>
  Math.min(line?.product?.max_quantity ?? HARD_MAX_QUANTITY, HARD_MAX_QUANTITY);

/**
 * How many of one piece the basket already holds, across every colourway — the server's
 * cap is on the product, not on the line, so two glazes of the same mug share it.
 */
export const quantityOf = (items, productId) =>
  asList(items).reduce(
    (sum, line) =>
      line.product?.id === productId ? sum + (line.quantity ?? 0) : sum,
    0,
  );

export const useCart = () => {
  const api = useApi();
  const { isRegistered } = useIsRegistered();
  const local = useLocalCart();

  const { data, pending, error, refresh } = useApiFetch("/api/shop/cart", {
    key: "cart",
    transform: (res) => res?.data ?? { items: [], total_price: "0.00" },
    default: () => ({ items: [], total_price: "0.00" }),
    immediate: isRegistered.value,
    watch: [isRegistered],
  });

  const items = computed(() =>
    isRegistered.value ? asList(data.value?.items) : local.items.value,
  );
  const total = computed(() =>
    isRegistered.value
      ? (data.value?.total_price ?? "0.00")
      : local.total.value,
  );
  const count = computed(() =>
    isRegistered.value
      ? items.value.reduce((sum, line) => sum + (line.quantity ?? 0), 0)
      : local.count.value,
  );
  const hasOutOfStock = computed(() =>
    items.value.some((line) => line.in_stock === false),
  );
  const canCheckout = computed(
    () => items.value.length > 0 && !hasOutOfStock.value,
  );

  /**
   * `POST` increments an existing line; the server answers the line it touched.
   *
   * No colour: `shop_cart_items` has no column for one and the endpoint's validator
   * accepts only `shop_product_id` and `quantity`, so a glaze sent here was silently
   * dropped. The product's colours are a legend on the detail page, not a variant.
   */
  const add = async (productId, quantity = 1) => {
    if (!isRegistered.value) return local.add(productId, quantity);
    const res = await api("/api/shop/cart", {
      method: "POST",
      body: { shop_product_id: productId, quantity },
    });
    await refresh();
    return res;
  };

  /** `PUT` sets the quantity outright. */
  const update = async (lineId, quantity) => {
    if (!isRegistered.value) return local.update(lineId, quantity);
    const res = await api(`/api/shop/cart/${lineId}`, {
      method: "PUT",
      body: { quantity },
    });
    await refresh();
    return res;
  };

  const remove = async (lineId) => {
    if (!isRegistered.value) return local.remove(lineId);
    const res = await api(`/api/shop/cart/${lineId}`, { method: "DELETE" });
    await refresh();
    return res;
  };

  const cart = computed(() =>
    isRegistered.value
      ? data.value
      : { items: local.items.value, total_price: local.total.value },
  );

  return {
    cart,
    items,
    total,
    count,
    hasOutOfStock,
    canCheckout,
    isRegistered,
    pending: computed(() =>
      isRegistered.value ? pending.value : local.pending.value,
    ),
    error: computed(() =>
      isRegistered.value ? error.value : local.error.value,
    ),
    refresh: () => (isRegistered.value ? refresh() : local.refresh()),
    add,
    update,
    remove,
  };
};

/**
 * Checkout state: the three inputs (`address_id`, `discount_code`, `use_wallet`), a quote
 * that follows every change to them or to the cart, and the create/pay calls with the
 * identical inputs. Whatever the server returns is rendered as-is — totals are never
 * patched locally.
 */
export const useCheckout = () => {
  const api = useApi();
  const cart = useCart();

  const addressId = ref(null);
  const discountCode = ref("");
  const useWallet = ref(false);

  const quote = ref(null);
  const quoting = ref(false);
  const errors = ref({});
  const error = ref("");

  /** The order this session created, or the open hold found when checkout was refused. */
  const order = ref(null);
  const resumed = ref(false);

  const body = () => ({
    address_id: addressId.value ?? undefined,
    use_wallet: useWallet.value,
    discount_code: discountCode.value || undefined,
  });

  let sequence = 0;
  const requote = async () => {
    const mine = ++sequence;
    if (!cart.items.value.length) {
      quote.value = null;
      return;
    }
    quoting.value = true;
    try {
      const res = await api("/api/shop/cart/quote", {
        method: "POST",
        body: body(),
      });
      if (mine !== sequence) return;
      quote.value = res?.data ?? null;
      // A refused coupon bounces back into the input, which requotes without it — keep the
      // refusal on screen until another code is tried.
      if (discountCode.value || !errors.value.discount_code) errors.value = {};
      error.value = "";
    } catch (err) {
      if (mine !== sequence) return;
      const normalized = normalizeApiError(err);
      errors.value = normalized.errors;
      error.value = normalized.message;
      quote.value = null;
    } finally {
      if (mine === sequence) quoting.value = false;
    }
  };

  watch([addressId, discountCode, useWallet, () => cart.items.value], requote, {
    immediate: true,
  });

  const settled = computed(
    () =>
      !!order.value &&
      (order.value.payment_status === "paid" ||
        isZeroMoney(order.value.amount_due)),
  );

  const checkout = async () => {
    errors.value = {};
    error.value = "";
    resumed.value = false;
    try {
      const res = await api("/api/shop/cart/checkout", {
        method: "POST",
        body: body(),
      });
      order.value = res?.data ?? null;
      // Covered in full by the wallet or a coupon: the server settled it and emptied the cart.
      if (settled.value) await cart.refresh();
      return order.value;
    } catch (err) {
      const normalized = normalizeApiError(err);
      errors.value = normalized.errors;
      error.value = normalized.message;
      if (normalized.errors.cart) {
        const open = await findAwaitingPayment();
        if (open) {
          order.value = open;
          resumed.value = true;
        }
      }
      throw normalized;
    }
  };

  /** Only one hold is open at a time, so the newest page is enough to find it. */
  const findAwaitingPayment = async () => {
    try {
      const res = await api("/api/shop/orders", { query: { per_page: 5 } });
      return (
        unwrapList(res?.data).items.find(
          (candidate) => candidate.status === "awaiting_payment",
        ) ?? null
      );
    } catch {
      return null;
    }
  };

  const pay = async () => {
    const res = await api(`/api/shop/orders/${order.value.id}/pay`, {
      method: "POST",
    });
    order.value = res?.data ?? order.value;
    await cart.refresh();
    return res;
  };

  /** After the open hold is cancelled the basket is untouched — back to a fresh quote. */
  const reset = () => {
    order.value = null;
    resumed.value = false;
    errors.value = {};
    error.value = "";
    return requote();
  };

  return {
    cart,
    addressId,
    discountCode,
    useWallet,
    quote,
    quoting,
    errors,
    error,
    order,
    resumed,
    settled,
    requote,
    checkout,
    pay,
    reset,
  };
};
