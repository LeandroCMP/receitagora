import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';
import 'package:receitagora/services/recipe/notebooks/favorites_notebook_service.dart';
import 'package:receitagora/services/session/session_service.dart';

class FavoritesNotebookServiceImpl extends GetxService
    implements FavoritesNotebookService {
  FavoritesNotebookServiceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
    required SessionService sessionService,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        _sessionService = sessionService;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SessionService _sessionService;

  final RxList<FavoritesNotebook> _notebooks = <FavoritesNotebook>[].obs;
  final Map<String, FavoritesNotebook> _cache = <String, FavoritesNotebook>{};

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ownedSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sharedIndexSubscription;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _collaborationSubscriptions =
      <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};

  @override
  List<FavoritesNotebook> get notebooks => List<FavoritesNotebook>.unmodifiable(
        _notebooks,
      );

  @override
  Stream<List<FavoritesNotebook>> get notebooksStream => _notebooks.stream;

  @override
  void onInit() {
    super.onInit();
    _authSubscription =
        _firebaseAuth.userChanges().listen(_handleUserChanged);
    _handleUserChanged(_firebaseAuth.currentUser);
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _clearSubscriptions();
    super.onClose();
  }

  void _handleUserChanged(User? user) {
    _clearSubscriptions();
    _cache.clear();
    _notebooks.clear();

    if (user == null) {
      return;
    }

    _ownedSubscription = _userCollection(user.uid).snapshots().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) {
            continue;
          }
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              final notebook = _mapNotebook(
                data: data,
                id: change.doc.id,
                ownerId: user.uid,
                isOwner: true,
              );
              _putNotebook(notebook);
              if (notebook.isCollaborative) {
                _ensureShareIndex(notebook);
              } else {
                _removeShareIndex(notebook);
              }
              break;
            case DocumentChangeType.removed:
              _removeNotebook(user.uid, change.doc.id);
              break;
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        Get.log(
          'Erro ao acompanhar cadernos do usuário: $error\n$stackTrace',
          isError: true,
        );
      },
    );

    _sharedIndexSubscription = _firestore
        .collection('sharedFavoriteNotebooks')
        .where('collaborators', arrayContains: user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        final knownKeys = <String>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final ownerId = data['ownerId'] as String?;
          final notebookId = data['notebookId'] as String?;
          if (ownerId == null || notebookId == null) {
            continue;
          }
          final key = _composeKey(ownerId, notebookId);
          knownKeys.add(key);
          _collaborationSubscriptions[key] ??=
              _userCollection(ownerId).doc(notebookId).snapshots().listen(
            (document) {
              final payload = document.data();
              if (payload == null) {
                _removeNotebook(ownerId, notebookId);
                return;
              }
              final notebook = _mapNotebook(
                data: payload,
                id: notebookId,
                ownerId: ownerId,
                isOwner: ownerId == user.uid,
              );
              _putNotebook(notebook.copyWith(isOwner: ownerId == user.uid));
            },
            onError: (Object error, StackTrace stackTrace) {
              Get.log(
                'Erro ao acompanhar caderno compartilhado: $error\n$stackTrace',
                isError: true,
              );
            },
          );
        }

        final removedKeys = _collaborationSubscriptions.keys
            .where((key) => !knownKeys.contains(key))
            .toList();
        for (final key in removedKeys) {
          _collaborationSubscriptions.remove(key)?.cancel();
          final parts = key.split('::');
          if (parts.length == 2) {
            _removeNotebook(parts[0], parts[1]);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        Get.log(
          'Erro ao acompanhar índice de cadernos compartilhados: '
          '$error\n$stackTrace',
          isError: true,
        );
      },
    );
  }

  void _clearSubscriptions() {
    _ownedSubscription?.cancel();
    _sharedIndexSubscription?.cancel();
    for (final entry in _collaborationSubscriptions.entries) {
      entry.value.cancel();
    }
    _collaborationSubscriptions.clear();
  }

  CollectionReference<Map<String, dynamic>> _userCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteNotebooks');
  }

  CollectionReference<Map<String, dynamic>> get _sharedCollection =>
      _firestore.collection('sharedFavoriteNotebooks');

  FavoritesNotebook _mapNotebook({
    required Map<String, dynamic> data,
    required String id,
    required String ownerId,
    required bool isOwner,
  }) {
    final title = (data['title'] as String? ?? 'Caderno sem título').trim();
    final description = (data['description'] as String?)?.trim();
    final shareCode = data['shareCode'] as String?;
    final isCollaborative = data['isCollaborative'] as bool? ?? false;
    final favoriteIds = <String>[];
    final favoritesRaw = data['favoriteIds'];
    if (favoritesRaw is Iterable) {
      for (final item in favoritesRaw) {
        favoriteIds.add(item.toString());
      }
    }

    final members = <FavoritesNotebookMember>[];
    final membersRaw = data['members'];
    if (membersRaw is Iterable) {
      for (final item in membersRaw) {
        if (item is Map<String, dynamic>) {
          final memberId = item['id'] as String?;
          final name = (item['name'] as String?)?.trim();
          if (memberId != null && name != null && name.isNotEmpty) {
            members.add(FavoritesNotebookMember(id: memberId, name: name));
          }
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final memberId = map['id'] as String?;
          final name = (map['name'] as String?)?.trim();
          if (memberId != null && name != null && name.isNotEmpty) {
            members.add(FavoritesNotebookMember(id: memberId, name: name));
          }
        }
      }
    }

    final comments = <FavoritesNotebookComment>[];
    final commentsRaw = data['comments'];
    if (commentsRaw is Iterable) {
      for (final item in commentsRaw) {
        if (item is Map<String, dynamic>) {
          final commentId = item['id'] as String? ?? '';
          final authorId = item['authorId'] as String? ?? '';
          final authorName = item['authorName'] as String? ?? 'Colaborador';
          final message = item['message'] as String? ?? '';
          final createdAtRaw = item['createdAt'];
          DateTime createdAt = DateTime.now();
          if (createdAtRaw is Timestamp) {
            createdAt = createdAtRaw.toDate();
          } else if (createdAtRaw is DateTime) {
            createdAt = createdAtRaw;
          } else if (createdAtRaw is String) {
            createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
          }
          if (message.trim().isNotEmpty) {
            comments.add(
              FavoritesNotebookComment(
                id: commentId,
                authorId: authorId,
                authorName: authorName,
                message: message,
                createdAt: createdAt,
              ),
            );
          }
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final commentId = map['id'] as String? ?? '';
          final authorId = map['authorId'] as String? ?? '';
          final authorName = map['authorName'] as String? ?? 'Colaborador';
          final message = map['message'] as String? ?? '';
          final createdAtRaw = map['createdAt'];
          DateTime createdAt = DateTime.now();
          if (createdAtRaw is Timestamp) {
            createdAt = createdAtRaw.toDate();
          } else if (createdAtRaw is DateTime) {
            createdAt = createdAtRaw;
          } else if (createdAtRaw is String) {
            createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
          }
          if (message.trim().isNotEmpty) {
            comments.add(
              FavoritesNotebookComment(
                id: commentId,
                authorId: authorId,
                authorName: authorName,
                message: message,
                createdAt: createdAt,
              ),
            );
          }
        }
      }
    }

    final ownerName = (data['ownerName'] as String? ?? 'Colaborador').trim();
    final updatedAtRaw = data['updatedAt'];
    DateTime updatedAt = DateTime.now();
    if (updatedAtRaw is Timestamp) {
      updatedAt = updatedAtRaw.toDate();
    } else if (updatedAtRaw is DateTime) {
      updatedAt = updatedAtRaw;
    } else if (updatedAtRaw is String) {
      updatedAt = DateTime.tryParse(updatedAtRaw) ?? DateTime.now();
    }

    final notebookMembers = members.isEmpty
        ? <FavoritesNotebookMember>[
            FavoritesNotebookMember(id: ownerId, name: ownerName),
          ]
        : members;

    return FavoritesNotebook(
      id: id,
      title: title,
      description: description,
      ownerId: ownerId,
      ownerName: ownerName.isEmpty ? 'Colaborador' : ownerName,
      isCollaborative: isCollaborative,
      shareCode: shareCode,
      favoriteIds: List<String>.unmodifiable(favoriteIds),
      members: List<FavoritesNotebookMember>.unmodifiable(notebookMembers),
      comments: List<FavoritesNotebookComment>.unmodifiable(
        comments..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ),
      isOwner: isOwner,
      updatedAt: updatedAt,
    );
  }

  void _putNotebook(FavoritesNotebook notebook) {
    final key = _composeKey(notebook.ownerId, notebook.id);
    _cache[key] = notebook;
    _notebooks.assignAll(
      _cache.values
          .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  void _removeNotebook(String ownerId, String notebookId) {
    final key = _composeKey(ownerId, notebookId);
    _cache.remove(key);
    _notebooks.assignAll(
      _cache.values
          .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  String _composeKey(String ownerId, String notebookId) => '$ownerId::$notebookId';

  @override
  Future<FavoritesNotebook> createNotebook({
    required String title,
    String? description,
    bool collaborative = false,
  }) async {
    final user = _requireUser();
    final doc = _userCollection(user.uid).doc();
    final sanitizedTitle = title.trim().isEmpty ? 'Novo caderno' : title.trim();
    final sanitizedDescription = description?.trim();
    final ownerName = _sessionService.user?.name ??
        user.displayName ??
        'Você';

    final payload = <String, dynamic>{
      'title': sanitizedTitle,
      'description': sanitizedDescription,
      'ownerName': ownerName,
      'isCollaborative': collaborative,
      'shareCode': collaborative ? _generateShareCode() : null,
      'favoriteIds': <String>[],
      'members': <Map<String, String>>[
        <String, String>{'id': user.uid, 'name': ownerName},
      ],
      'comments': <Map<String, dynamic>>[],
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await doc.set(payload);

    if (collaborative && payload['shareCode'] != null) {
      await _sharedCollection.doc(payload['shareCode'] as String).set({
        'ownerId': user.uid,
        'notebookId': doc.id,
        'title': sanitizedTitle,
        'collaborators': <String>[user.uid],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final notebook = FavoritesNotebook(
      id: doc.id,
      title: sanitizedTitle,
      description: sanitizedDescription,
      ownerId: user.uid,
      ownerName: ownerName,
      isCollaborative: collaborative,
      shareCode: collaborative ? payload['shareCode'] as String? : null,
      favoriteIds: const <String>[],
      members: <FavoritesNotebookMember>[
        FavoritesNotebookMember(id: user.uid, name: ownerName),
      ],
      comments: const <FavoritesNotebookComment>[],
      isOwner: true,
      updatedAt: DateTime.now(),
    );
    _putNotebook(notebook);
    return notebook;
  }

  @override
  Future<void> updateNotebook({
    required String notebookId,
    String? title,
    String? description,
    bool? collaborative,
  }) async {
    final user = _requireUser();
    final doc = _userCollection(user.uid).doc(notebookId);

    final updates = <String, dynamic>{};
    if (title != null) {
      updates['title'] = title.trim().isEmpty ? 'Caderno' : title.trim();
    }
    if (description != null) {
      final sanitized = description.trim();
      updates['description'] = sanitized.isEmpty ? null : sanitized;
    }
    if (collaborative != null) {
      updates['isCollaborative'] = collaborative;
      if (!collaborative) {
        updates['shareCode'] = null;
      }
    }
    if (updates.isEmpty) {
      return;
    }
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await doc.set(updates, SetOptions(merge: true));

    if (collaborative != null) {
      if (collaborative) {
        final shareCode = await ensureShareCode(notebookId);
        if (shareCode != null) {
          await _sharedCollection.doc(shareCode).set({
            'ownerId': user.uid,
            'notebookId': notebookId,
            'title': updates['title'] ??
                _cache[_composeKey(user.uid, notebookId)]?.title ??
                'Caderno',
            'collaborators': FieldValue.arrayUnion(<String>[user.uid]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else {
        final notebook = _cache[_composeKey(user.uid, notebookId)];
        final shareCode = notebook?.shareCode;
        if (shareCode != null) {
          await _sharedCollection.doc(shareCode).delete().catchError((_) {});
        }
      }
    }
  }

  @override
  Future<void> deleteNotebook(String notebookId) async {
    final user = _requireUser();
    final notebook = _cache[_composeKey(user.uid, notebookId)];
    await _userCollection(user.uid).doc(notebookId).delete();
    if (notebook?.shareCode != null) {
      await _sharedCollection.doc(notebook!.shareCode).delete().catchError((_) {});
    }
  }

  @override
  Future<void> addFavorite({
    required String notebookId,
    required FavoritedRecipeEntity favorite,
  }) async {
    final notebook = _findNotebookForCurrentUser(notebookId);
    final ownerId = notebook?.ownerId;
    if (ownerId == null) {
      return;
    }

    final doc = _userCollection(ownerId).doc(notebookId);
    await doc.set(
      <String, dynamic>{
        'favoriteIds': FieldValue.arrayUnion(<String>[favorite.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> removeFavorite({
    required String notebookId,
    required String favoriteId,
  }) async {
    final notebook = _findNotebookForCurrentUser(notebookId);
    final ownerId = notebook?.ownerId;
    if (ownerId == null) {
      return;
    }

    final doc = _userCollection(ownerId).doc(notebookId);
    await doc.set(
      <String, dynamic>{
        'favoriteIds': FieldValue.arrayRemove(<String>[favoriteId]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> addComment({
    required String notebookId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final user = _firebaseAuth.currentUser;
    final notebook = _findNotebookForCurrentUser(notebookId);
    final ownerId = notebook?.ownerId;
    if (ownerId == null) {
      return;
    }

    final commentId = '${DateTime.now().microsecondsSinceEpoch}';
    final authorName = _sessionService.user?.name ??
        user?.displayName ??
        'Colaborador';

    final doc = _userCollection(ownerId).doc(notebookId);
    await doc.set(
      <String, dynamic>{
        'comments': FieldValue.arrayUnion(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': commentId,
            'authorId': user?.uid ?? '',
            'authorName': authorName,
            'message': trimmed,
            'createdAt': FieldValue.serverTimestamp(),
          },
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<String?> ensureShareCode(String notebookId) async {
    final user = _requireUser();
    final docRef = _userCollection(user.uid).doc(notebookId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    var shareCode = data['shareCode'] as String?;
    if (shareCode == null || shareCode.isEmpty) {
      shareCode = _generateShareCode();
      await docRef.set(<String, dynamic>{
        'shareCode': shareCode,
        'isCollaborative': true,
        'members': FieldValue.arrayUnion(<Map<String, String>>[
          <String, String>{
            'id': user.uid,
            'name': _sessionService.user?.name ??
                user.displayName ??
                'Você',
          },
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _sharedCollection.doc(shareCode).set({
        'ownerId': user.uid,
        'notebookId': notebookId,
        'title': data['title'] as String? ?? 'Caderno',
        'collaborators': <String>[user.uid],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return shareCode;
  }

  @override
  Future<void> joinByShareCode(String shareCode) async {
    final sanitized = shareCode.trim().toUpperCase();
    if (sanitized.isEmpty) {
      return;
    }
    final user = _requireUser();
    final doc = await _sharedCollection.doc(sanitized).get();
    final data = doc.data();
    if (data == null) {
      throw StateError('Código de compartilhamento inválido.');
    }
    final ownerId = data['ownerId'] as String?;
    final notebookId = data['notebookId'] as String?;
    if (ownerId == null || notebookId == null) {
      throw StateError('Código de compartilhamento inválido.');
    }

    final ownerDoc = _userCollection(ownerId).doc(notebookId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ownerDoc);
      final payload = snapshot.data() ?? <String, dynamic>{};
      final existingMembers = payload['members'];
      final members = <Map<String, String>>[];
      if (existingMembers is Iterable) {
        for (final item in existingMembers) {
          if (item is Map<String, dynamic>) {
            final id = item['id'] as String?;
            final name = item['name'] as String?;
            if (id != null && name != null) {
              members.add(<String, String>{'id': id, 'name': name});
            }
          } else if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id'] as String?;
            final name = map['name'] as String?;
            if (id != null && name != null) {
              members.add(<String, String>{'id': id, 'name': name});
            }
          }
        }
      }
      final alreadyMember = members.any((member) => member['id'] == user.uid);
      if (!alreadyMember) {
        members.add(<String, String>{
          'id': user.uid,
          'name': _sessionService.user?.name ??
              user.displayName ??
              'Colaborador',
        });
      }
      transaction.set(
        ownerDoc,
        <String, dynamic>{
          'isCollaborative': true,
          'shareCode': sanitized,
          'members': members,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      transaction.set(
        _sharedCollection.doc(sanitized),
        <String, dynamic>{
          'ownerId': ownerId,
          'notebookId': notebookId,
          'title': payload['title'] ?? data['title'] ?? 'Caderno',
          'collaborators': FieldValue.arrayUnion(<String>[user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<String> exportNotebook(
    String notebookId, {
    Map<String, FavoritedRecipeEntity>? favoritesById,
  }) async {
    final notebook = _cache.values.firstWhereOrNull(
      (element) => element.id == notebookId,
    );
    if (notebook == null) {
      return 'Caderno não encontrado.';
    }

    final buffer = StringBuffer()
      ..writeln('Caderno: ${notebook.title}')
      ..writeln('Organizado por ${notebook.ownerName}')
      ..writeln();

    if (notebook.description != null && notebook.description!.isNotEmpty) {
      buffer
        ..writeln('Descrição:')
        ..writeln(notebook.description!)
        ..writeln();
    }

    buffer.writeln('Favoritos inclusos:');
    if (notebook.favoriteIds.isEmpty) {
      buffer.writeln('- Nenhuma receita adicionada ainda.');
    } else {
      for (final id in notebook.favoriteIds) {
        final recipe = favoritesById?[id]?.recipe;
        final title = recipe?.name ?? 'Receita $id';
        buffer.writeln('- $title');
      }
    }

    if (notebook.shareCode != null) {
      buffer
        ..writeln()
        ..writeln('Código para colaborar: ${notebook.shareCode}');
    }

    return buffer.toString();
  }

  User _requireUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Faça login para gerenciar cadernos.');
    }
    return user;
  }

  void _ensureShareIndex(FavoritesNotebook notebook) {
    final shareCode = notebook.shareCode;
    if (shareCode == null || shareCode.isEmpty) {
      return;
    }
    _sharedCollection.doc(shareCode).set({
      'ownerId': notebook.ownerId,
      'notebookId': notebook.id,
      'title': notebook.title,
      'collaborators': FieldValue.arrayUnion(
        <String>[notebook.ownerId],
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _removeShareIndex(FavoritesNotebook notebook) {
    final shareCode = notebook.shareCode;
    if (shareCode == null || shareCode.isEmpty) {
      return;
    }
    _sharedCollection.doc(shareCode).delete().catchError((_) {});
  }

  String _generateShareCode() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (index) => characters[random.nextInt(characters.length)])
        .join();
  }

  FavoritesNotebook? _findNotebookForCurrentUser(String notebookId) {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return null;
    }
    final own = _cache[_composeKey(userId, notebookId)];
    if (own != null) {
      return own;
    }
    return _cache.values.firstWhereOrNull(
      (entry) => entry.id == notebookId &&
          entry.members.any((member) => member.id == userId),
    );
  }
}

extension on FavoritesNotebook {
  FavoritesNotebook copyWith({
    bool? isOwner,
  }) {
    return FavoritesNotebook(
      id: id,
      title: title,
      description: description,
      ownerId: ownerId,
      ownerName: ownerName,
      isCollaborative: isCollaborative,
      shareCode: shareCode,
      favoriteIds: favoriteIds,
      members: members,
      comments: comments,
      isOwner: isOwner ?? this.isOwner,
      updatedAt: updatedAt,
    );
  }
}
