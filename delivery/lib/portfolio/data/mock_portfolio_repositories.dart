import 'dart:typed_data';

import '../models/editable_content.dart';
import '../models/portfolio_project.dart';
import '../repositories/editable_content_repository.dart';
import '../repositories/image_storage_repository.dart';
import '../repositories/portfolio_project_repository.dart';

/// Mock implementation of [PortfolioProjectRepository] for local development.
class MockPortfolioProjectRepository implements PortfolioProjectRepository {
  final List<PortfolioProject> _projects = [
    PortfolioProject(
      id: '1',
      title: 'App de Delivery',
      description:
          'Aplicación móvil para gestión de entregas a domicilio con seguimiento en tiempo real, panel de repartidores y administración completa.',
      mainImageUrl: 'https://picsum.photos/seed/delivery/800/600',
      additionalImageUrls: [
        'https://picsum.photos/seed/delivery2/800/600',
        'https://picsum.photos/seed/delivery3/800/600',
      ],
      externalLink: 'https://github.com/example/delivery-app',
      technologies: ['Flutter', 'Dart', 'Firebase', 'Riverpod'],
      isFeatured: true,
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 6, 1),
    ),
    PortfolioProject(
      id: '2',
      title: 'Server Manager',
      description:
          'Herramienta de administración de servidores de juegos con monitoreo, configuración remota y notificaciones push.',
      mainImageUrl: 'https://picsum.photos/seed/server/800/600',
      additionalImageUrls: [
        'https://picsum.photos/seed/server2/800/600',
      ],
      externalLink: 'https://github.com/example/server-manager',
      technologies: ['Flutter', 'Dart', 'REST API', 'WebSockets'],
      isFeatured: true,
      createdAt: DateTime(2024, 3, 10),
      updatedAt: DateTime(2024, 5, 20),
    ),
    PortfolioProject(
      id: '3',
      title: 'E-Commerce Platform',
      description:
          'Plataforma de comercio electrónico con catálogo de productos, carrito de compras, pasarela de pagos y panel administrativo.',
      mainImageUrl: 'https://picsum.photos/seed/ecommerce/800/600',
      additionalImageUrls: [],
      externalLink: null,
      technologies: ['Flutter', 'Node.js', 'PostgreSQL', 'Stripe'],
      isFeatured: true,
      createdAt: DateTime(2024, 5, 1),
      updatedAt: DateTime(2024, 6, 15),
    ),
    PortfolioProject(
      id: '4',
      title: 'Chat en Tiempo Real',
      description:
          'Aplicación de mensajería instantánea con soporte para grupos, envío de archivos y videollamadas.',
      mainImageUrl: 'https://picsum.photos/seed/chat/800/600',
      additionalImageUrls: [],
      technologies: ['Flutter', 'Firebase', 'WebRTC'],
      isFeatured: false,
      createdAt: DateTime(2023, 11, 5),
      updatedAt: DateTime(2024, 2, 10),
    ),
    PortfolioProject(
      id: '5',
      title: 'Dashboard Analytics',
      description:
          'Panel de analíticas con gráficos interactivos, reportes exportables y visualización de datos en tiempo real.',
      mainImageUrl: 'https://picsum.photos/seed/analytics/800/600',
      additionalImageUrls: [],
      technologies: ['Flutter Web', 'D3.js', 'REST API'],
      isFeatured: false,
      createdAt: DateTime(2023, 8, 20),
      updatedAt: DateTime(2024, 1, 5),
    ),
  ];

  @override
  Future<List<PortfolioProject>> getAllProjects() async => List.from(_projects);

  @override
  Future<List<PortfolioProject>> getFeaturedProjects() async =>
      _projects.where((p) => p.isFeatured).toList();

  @override
  Future<PortfolioProject?> getProjectById(String id) async =>
      _projects.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> createProject(PortfolioProject project) async {
    _projects.add(project);
  }

  @override
  Future<void> updateProject(PortfolioProject project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
  }

  @override
  Stream<List<PortfolioProject>> watchAllProjects() {
    return Stream.value(List<PortfolioProject>.from(_projects)).asBroadcastStream();
  }

  @override
  Stream<List<PortfolioProject>> watchFeaturedProjects() {
    return Stream.value(
      List<PortfolioProject>.from(_projects.where((p) => p.isFeatured)),
    ).asBroadcastStream();
  }
}

/// Mock implementation of [EditableContentRepository] for local development.
class MockEditableContentRepository implements EditableContentRepository {
  final List<EditableContent> _content = [
    EditableContent(
      id: 'hero-title',
      section: 'hero',
      key: 'title',
      value: 'Desarrollador Flutter',
      type: ContentType.title,
      updatedAt: DateTime(2024, 6, 1),
    ),
    EditableContent(
      id: 'hero-subtitle',
      section: 'hero',
      key: 'subtitle',
      value: 'Creando experiencias móviles y web excepcionales',
      type: ContentType.text,
      updatedAt: DateTime(2024, 6, 1),
    ),
    EditableContent(
      id: 'about-title',
      section: 'about',
      key: 'title',
      value: 'Sobre Mí',
      type: ContentType.title,
      updatedAt: DateTime(2024, 6, 1),
    ),
    EditableContent(
      id: 'about-description',
      section: 'about',
      key: 'description',
      value:
          'Soy un desarrollador apasionado por crear aplicaciones móviles y web de alta calidad usando Flutter y Dart.',
      type: ContentType.text,
      updatedAt: DateTime(2024, 6, 1),
    ),
    EditableContent(
      id: 'footer-copyright',
      section: 'footer',
      key: 'copyright',
      value: '© 2024 Mi Portafolio. Todos los derechos reservados.',
      type: ContentType.text,
      updatedAt: DateTime(2024, 6, 1),
    ),
  ];

  @override
  Future<List<EditableContent>> getAllContent() async => List.from(_content);

  @override
  Future<List<EditableContent>> getContentBySection(String section) async =>
      _content.where((c) => c.section == section).toList();

  @override
  Future<void> updateContent(EditableContent content) async {
    final index = _content.indexWhere((c) => c.id == content.id);
    if (index != -1) {
      _content[index] = content;
    }
  }

  @override
  Stream<List<EditableContent>> watchContentBySection(String section) {
    return Stream.value(
      _content.where((c) => c.section == section).toList(),
    ).asBroadcastStream();
  }
}

/// Mock implementation of [ImageStorageRepository] for local development.
class MockImageStorageRepository implements ImageStorageRepository {
  @override
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    // Simulate upload delay
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://picsum.photos/seed/$filename/800/600';
  }

  @override
  Future<void> deleteImage(String url) async {
    // No-op for mock
  }

  @override
  Future<bool> validateImage(Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    const allowed = ['png', 'jpg', 'jpeg', 'webp'];
    if (!allowed.contains(ext)) return false;
    if (bytes.length > 5 * 1024 * 1024) return false;
    return true;
  }
}
