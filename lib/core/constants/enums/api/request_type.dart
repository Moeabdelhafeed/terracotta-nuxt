enum RequestType {
  get,
  post,
  put,
  delete,
  patch,
  multipart,
  ;

  String get name => switch (this) {
    .get => 'GET',
    .post => 'POST',
    .put => 'PUT',
    .delete => 'DELETE',
    .patch => 'PATCH',
    .multipart => 'POST',
  };

  bool get hasBody => switch (this) {
    .get => false,
    .post => true,
    .put => true,
    .delete => false,
    .patch => true,
    .multipart => true,
  };

  bool get cacheable => switch (this) {
    .get => true,
    .post => false,
    .put => true,
    .delete => false,
    .patch => true,
    .multipart => false,
  };

  bool get isReadOperation => this == RequestType.get;
  bool get isWriteOperation => hasBody;
  bool get isSafe => this == RequestType.get;
  bool get isIdempotent =>
      this == RequestType.get ||
      this == RequestType.put ||
      this == RequestType.delete;

  Map<String, String> getDefaultHeaders() => <String, String>{
    if (hasBody && this != RequestType.multipart)
      'Content-Type': 'application/json',
    if (cacheable)
      'Cache-Control': 'max-age=300'
    else
      'Cache-Control': 'no-cache',
  };
}
