class AvatarOption {
  const AvatarOption({required this.id, required this.assetPath});

  final String id;
  final String assetPath;
}

const avatarOptions = <AvatarOption>[
  AvatarOption(id: 'avatar_01', assetPath: 'assets/avatars/avatar_01.png'),
  AvatarOption(id: 'avatar_02', assetPath: 'assets/avatars/avatar_02.png'),
  AvatarOption(id: 'avatar_03', assetPath: 'assets/avatars/avatar_03.png'),
  AvatarOption(id: 'avatar_04', assetPath: 'assets/avatars/avatar_04.png'),
  AvatarOption(id: 'avatar_05', assetPath: 'assets/avatars/avatar_05.png'),
  AvatarOption(id: 'avatar_06', assetPath: 'assets/avatars/avatar_06.png'),
  AvatarOption(id: 'avatar_07', assetPath: 'assets/avatars/avatar_07.png'),
  AvatarOption(id: 'avatar_08', assetPath: 'assets/avatars/avatar_08.png'),
];

AvatarOption avatarOptionById(String? id) {
  return avatarOptions.firstWhere(
    (option) => option.id == id,
    orElse: () => avatarOptions.first,
  );
}
