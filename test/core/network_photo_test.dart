import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/widgets/network_photo.dart';

const _cdn =
    'https://res.cloudinary.com/demo/image/upload/v1795005195/product_images/7622202818400.jpg';

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8000'));

  group('cloudinarySized', () {
    test('asks for the next size step, never more than the stored 800', () {
      expect(
        cloudinarySized(_cdn, 186),
        'https://res.cloudinary.com/demo/image/upload/c_limit,w_256,h_256,q_auto/v1795005195/product_images/7622202818400.jpg',
      );
      expect(
        cloudinarySized(_cdn, 100),
        contains('/c_limit,w_128,h_128,q_auto/'),
      );
      expect(
        cloudinarySized(_cdn, 3000),
        contains('/c_limit,w_800,h_800,q_auto/'),
      );
    });

    test(
      'a URL without a version (folder right after upload) is resized too',
      () {
        expect(
          cloudinarySized(
            'https://res.cloudinary.com/demo/image/upload/product_images/1.jpg',
            200,
          ),
          'https://res.cloudinary.com/demo/image/upload/c_limit,w_256,h_256,q_auto/product_images/1.jpg',
        );
      },
    );

    test('keeps a URL that already has a transformation', () {
      const shaped =
          'https://res.cloudinary.com/demo/image/upload/w_100,c_fill/v1/a.jpg';
      expect(cloudinarySized(shaped, 300), shaped);
    });

    test('leaves non-Cloudinary URLs alone', () {
      const off =
          'https://images.openbeautyfacts.org/images/products/871/front_en.20.400.jpg';
      expect(cloudinarySized(off, 200), off);
      expect(
        cloudinarySized(
          'https://res.cloudinary.com/demo/video/upload/v1/a.mp4',
          200,
        ),
        'https://res.cloudinary.com/demo/video/upload/v1/a.mp4',
      );
    });
  });

  testWidgets('no URL shows the placeholder right away', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NetworkPhoto(
          url: null,
          placeholder: Icon(Icons.inventory_2_outlined),
        ),
      ),
    );
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });
}
