class Category {
  final int id;
  final String name;

  const Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Property {
  final int id;
  final String title;
  final String description;
  final String type;
  final String status;
  final double? price;
  final double? pricePerMonth;
  final String location;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final double rating;
  final String image;
  final bool featured;
  final String? propertyLabel;
  final double? latitude;
  final double? longitude;

  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.price,
    this.pricePerMonth,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.rating,
    required this.image,
    required this.featured,
    this.propertyLabel,
    this.latitude,
    this.longitude,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'price': price,
      'priceType': pricePerMonth != null ? 'month' : 'total',
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'rating': rating,
      'image': image,
      'featured': featured,
      'propertyLabel': propertyLabel,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      pricePerMonth: json['price_per_month'] != null ? double.tryParse(json['price_per_month'].toString()) : null,
      location: json['location'] ?? '',
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      area: json['area'] != null ? double.parse(json['area'].toString()) : 0.0,
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : 0.0,
      // Handle the image mapping robustly. Check if there are photos.
      image: (json['photos'] != null && (json['photos'] as List).isNotEmpty)
          ? (json['photos'][0]['full_url'] ?? json['photos'][0]['url'] ?? 'https://placehold.co/800x600/20B2AA/FFFFFF/png?text=Darna+Image')
          : 'https://placehold.co/800x600/20B2AA/FFFFFF/png?text=Darna+Image',
      featured: json['featured'] == 1 || json['featured'] == true,
      propertyLabel: json['property_label'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }
}

class PropertyType {
  final int id;
  final String name;
  final String value;

  const PropertyType({required this.id, required this.name, required this.value});
}

class PropertyStatus {
  final int id;
  final String name;
  final String value;

  const PropertyStatus({required this.id, required this.name, required this.value});
}

class PropertiesData {
  static const List<Category> categories = [
    Category(id: 1, name: 'All'),
    Category(id: 2, name: 'Apartment'),
    Category(id: 3, name: 'House'),
  ];

  static const List<Property> properties = [
    Property(
      id: 1,
      title: 'Halloween Sale!',
      description: 'All discount up to 80%',
      type: 'House',
      status: 'For Sale',
      price: 1850000,
      pricePerMonth: null,
      location: 'Laayoune, Bloc I',
      bedrooms: 4,
      bathrooms: 3,
      area: 250,
      rating: 4.9,
      image: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      featured: true,
    ),
    Property(
      id: 2,
      title: 'House For Rent',
      description: 'All discount up to 80%',
      type: 'House',
      status: 'For Rent',
      price: null,
      pricePerMonth: 4500,
      location: 'Laayoune, Bloc I',
      bedrooms: 5,
      bathrooms: 4,
      area: 320,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
      featured: true,
    ),
    Property(
      id: 3,
      title: 'Summer Vacation',
      description: 'All discount up to 60%',
      type: 'House',
      status: 'For Rent',
      price: null,
      pricePerMonth: 3200,
      location: 'Laayoune, Bloc I',
      bedrooms: 3,
      bathrooms: 2,
      area: 180,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=800',
      featured: true,
    ),
    Property(
      id: 4,
      title: 'Basement Apartment',
      description: 'Cozy apartment in the heart of the city',
      type: 'Apartment',
      status: 'For Rent',
      price: null,
      pricePerMonth: 2200,
      location: 'Laayoune, Bloc I',
      bedrooms: 2,
      bathrooms: 1,
      area: 85,
      rating: 4.9,
      image: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      featured: false,
      propertyLabel: 'Apartment',
    ),
    Property(
      id: 5,
      title: 'Top Floor Apartment',
      description: 'Luxury penthouse with amazing views',
      type: 'Apartment',
      status: 'For Rent',
      price: null,
      pricePerMonth: 3800,
      location: 'Laayoune, Bloc I',
      bedrooms: 3,
      bathrooms: 2,
      area: 150,
      rating: 4.2,
      image: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
      featured: false,
      propertyLabel: 'Villa',
    ),
    Property(
      id: 6,
      title: 'Modern Villa',
      description: 'Beautiful villa with private pool',
      type: 'House',
      status: 'For Sale',
      price: 2950000,
      pricePerMonth: null,
      location: 'Laayoune, Bloc I',
      bedrooms: 6,
      bathrooms: 5,
      area: 450,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
      featured: false,
      propertyLabel: 'Villa',
    ),
  ];

  static const List<PropertyType> propertyTypes = [
    PropertyType(id: 1, name: 'Apartment', value: 'apartment'),
    PropertyType(id: 2, name: 'Villa', value: 'villa'),
  ];

  static const List<PropertyStatus> propertyStatus = [
    PropertyStatus(id: 1, name: 'All', value: 'all'),
    PropertyStatus(id: 2, name: 'Offplan', value: 'offplan'),
  ];
}

