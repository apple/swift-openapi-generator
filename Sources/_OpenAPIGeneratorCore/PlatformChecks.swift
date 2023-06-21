
// Details: https://github.com/apple/swift-openapi-generator/issues/86
#if os(iOS) || os(tvOS) || os(watchOS)
#error("Running the generator tool itself is not supported on iOS, tvOS, and watchOS. Check that your app is not linking the generator directly. For details, check out: https://github.com/apple/swift-openapi-generator/issues/86")
#endif
