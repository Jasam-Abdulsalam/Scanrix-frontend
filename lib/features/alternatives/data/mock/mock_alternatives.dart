/// Sample `GET /products/{barcode}/alternatives` response used until the
/// backend endpoint exists. Kept as raw JSON (not entities) on purpose: it goes
/// through `AlternativeProductModel.listFromJson`, so the parsing path is
/// exercised now and swapping in the real response changes nothing else.
///
/// DELETE this file once `GetAlternativesUseCase` calls the real API.
const Map<String, dynamic> mockAlternativesResponse = {
  'items': [
    {
      'barcode': '8901030865278',
      'name': 'Gentle Hydrating Cleanser',
      'brand': 'Cetaphil',
      'category': 'Face wash',
      'image_url': null,
      'overall_score': 92,
      'verdict': 'safe',
      'concern_count': 0,
      'highlights': ['Fragrance-free', 'No sulfates', 'Suitable for sensitive skin', 'Dermatologist tested'],
      'price': 399,
      'currency': 'INR',
    },
    {
      'barcode': '8906087770114',
      'name': 'Oat Calm Face Wash',
      'brand': 'Minimalist',
      'category': 'Face wash',
      'image_url': null,
      'overall_score': 86,
      'verdict': 'safe',
      'concern_count': 1,
      'highlights': ['Paraben-free', 'Soap-free formula', 'pH balanced'],
      'price': 349,
      'currency': 'INR',
    },
    {
      'barcode': '8904245700019',
      'name': 'Aloe Daily Cleanser',
      'brand': 'Plum',
      'category': 'Face wash',
      'image_url': null,
      'overall_score': 78,
      'verdict': 'safe',
      'concern_count': 1,
      'highlights': ['No artificial colours', 'Vegan', 'Mild surfactants'],
      'price': 325,
      'currency': 'INR',
    },
    {
      'barcode': '8901138511197',
      'name': 'Neem Purifying Wash',
      'brand': 'Himalaya',
      'category': 'Face wash',
      'image_url': null,
      'overall_score': 64,
      'verdict': 'caution',
      'concern_count': 2,
      'highlights': ['Lower fragrance load', 'No microplastics'],
      'price': 180,
      'currency': 'INR',
    },
  ],
};
