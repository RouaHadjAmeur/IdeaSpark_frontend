class BrandCollaborator {
  final String id;
  final String brandId;
  final String? brandName;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String inviterId;
  final String status; // pending | accepted | declined

  BrandCollaborator({
    required this.id,
    required this.brandId,
    this.brandName,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.inviterId,
    required this.status,
  });

  factory BrandCollaborator.fromJson(Map<String, dynamic> json) {
    final brandRaw = json['brandId'];
    final userRaw = json['userId'];
    final inviterRaw = json['inviterId'];

    return BrandCollaborator(
      id: json['_id'] ?? json['id'] ?? '',
      brandId: brandRaw is Map ? brandRaw['_id'] ?? '' : (brandRaw?.toString() ?? ''),
      brandName: brandRaw is Map ? brandRaw['name'] : null,
      userId: userRaw is Map ? userRaw['_id'] ?? '' : (userRaw?.toString() ?? ''),
      userName: userRaw is Map ? userRaw['displayName'] : null,
      userEmail: userRaw is Map ? userRaw['email'] : null,
      inviterId: inviterRaw is Map ? inviterRaw['_id'] ?? '' : (inviterRaw?.toString() ?? ''),
      status: json['status'] ?? 'pending',
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}
