/**
 * "This needs an account" — asked once, centred, instead of throwing the reader at
 * `/login` and losing where they were.
 *
 * State lives in `useState` so the middleware (which has no component to render into)
 * and the actions inside a page open the same dialog, and `LoginPrompt` in the layout is
 * the only thing that draws it.
 */
export const useLoginPrompt = () => {
  const target = useState("login-prompt", () => null);

  return {
    target,
    open: computed(() => target.value !== null),
    /** @param {string} redirect where to land once the account exists */
    ask: (redirect) => {
      target.value = redirect ?? "/";
    },
    dismiss: () => {
      target.value = null;
    },
  };
};
