String formatWithParams(String template, List<Object?> params) {
  var result = template;
  for (var i = 0; i < params.length; i += 1) {
    result = result.replaceAll('{$i}', params[i]?.toString() ?? '');
  }
  return result;
}
