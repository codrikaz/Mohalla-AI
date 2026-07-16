class AnonName {
  static String generate(String phoneHash) {
    // phoneHash is a 64-char hex string from SHA-256
    final b0 = int.parse(phoneHash.substring(0, 2), radix: 16);
    final b1 = int.parse(phoneHash.substring(2, 4), radix: 16);

    final block = String.fromCharCode(65 + (b0 % 26));
    const suffixes = ['Neighbour', 'Resident', 'Uncle', 'Aunty', 'Bhai'];
    final suffix = suffixes[b1 % suffixes.length];
    return 'Block $block $suffix';
  }
}
