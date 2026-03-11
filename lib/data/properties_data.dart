class Category {
  final int id;
  final String name;

  const Category({required this.id, required this.name});
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
    };
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
    Category(id: 4, name: 'Lands'),
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
    PropertyType(id: 1, name: 'Lands', value: 'lands'),
    PropertyType(id: 2, name: 'Apartment', value: 'apartment'),
    PropertyType(id: 3, name: 'Villa', value: 'villa'),
  ];

  static const List<PropertyStatus> propertyStatus = [
    PropertyStatus(id: 1, name: 'All', value: 'all'),
    PropertyStatus(id: 2, name: 'Offplan', value: 'offplan'),
  ];
}
