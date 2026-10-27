class BlockchainConfig {
  /// Alamat Smart Contract yang telah dideploy di Remix
  static const String contractAddress = '0x3d2b8556ca9872cedb25c58ef45262d358b1abc2';

  /// Alamat Dompet Wallet Pribadi Pemilik (Owner / Notarisasi)
  static const String walletAddress = '0xB6A78A100E5Eaa53544b4A46d36A8878D9119b95';

  /// Nama Jaringan / Tipe Kontrak
  static const String networkName = 'EVM / Remix Smart Contract';
  static const String contractName = 'PersonalHashPublisher';

  /// Format hash SHA-256 menjadi bytes32 (dengan prefix 0x) untuk parameter publishHash di Remix
  static String toBytes32(String hash) {
    final clean = hash.trim().replaceAll('0x', '');
    return '0x$clean';
  }

  /// Ringkasan alamat untuk tampilan UI (contoh: 0x3d2B...aBC2)
  static String shortContractAddress() {
    if (contractAddress.length < 10) return contractAddress;
    return '${contractAddress.substring(0, 6)}...${contractAddress.substring(contractAddress.length - 4)}';
  }

  /// Ringkasan alamat dompet untuk tampilan UI (contoh: 0xB6A7...9b95)
  static String shortWalletAddress() {
    if (walletAddress.length < 10) return walletAddress;
    return '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}';
  }
}
