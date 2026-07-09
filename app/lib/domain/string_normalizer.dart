String normalizeKey(String s) => s
    .toLowerCase()
    .trim()
    .replaceAll(' ', '_')
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');
