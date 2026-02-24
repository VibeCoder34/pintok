import '../models/home_feed_item.dart';

/// Mock data source for the Home Feed (Following, Explore, Local).
class HomeFeedRepository {
  HomeFeedRepository._();

  static final List<FollowingPost> following = [
    const FollowingPost(
      id: 'f1',
      userHandle: 'travel_guru',
      userAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      imageUrl: 'https://images.unsplash.com/photo-1495474474567-4c4de5f1a4a5?w=800',
      locationTag: 'Matcha Cafe · Kyoto',
      caption: 'Hidden gem in Gion. Best matcha latte and wagashi in town. 🍵',
      lat: 35.0016,
      lng: 135.7756,
      timeAgo: '2h ago',
    ),
    const FollowingPost(
      id: 'f2',
      userHandle: 'wanderlust_em',
      userAvatarUrl: null,
      imageUrl: 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800',
      locationTag: 'Eiffel Tower · Paris',
      caption: 'Golden hour from Trocadéro. No filter needed.',
      lat: 48.8584,
      lng: 2.2945,
      timeAgo: '5h ago',
    ),
    const FollowingPost(
      id: 'f3',
      userHandle: 'streetfood_istanbul',
      userAvatarUrl: null,
      imageUrl: 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800',
      locationTag: 'Grand Bazaar · Istanbul',
      caption: 'Simit and çay at the perfect spot. This is the one.',
      lat: 41.0106,
      lng: 28.9682,
      timeAgo: '1d ago',
    ),
    const FollowingPost(
      id: 'f4',
      userHandle: 'cafe_hopper',
      userAvatarUrl: null,
      imageUrl: 'https://images.unsplash.com/photo-1495474474567-4c4de5f1a4a5?w=800',
      locationTag: 'Café de Flore · Paris',
      caption: 'Where Sartre used to write. Still the best people-watching.',
      lat: 48.8540,
      lng: 2.3322,
      timeAgo: '2d ago',
    ),
  ];

  static final List<ExplorePin> explore = [
    const ExplorePin(
      id: 'e1',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
      locationLabel: 'Salinas Grandes · Argentina',
      curatedByGemini: true,
      lat: -23.6345,
      lng: -65.9432,
    ),
    const ExplorePin(
      id: 'e2',
      imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800',
      locationLabel: 'Starfield Library · Seoul',
      curatedByGemini: true,
      lat: 37.5133,
      lng: 127.1028,
    ),
    const ExplorePin(
      id: 'e3',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800',
      locationLabel: 'Hidden Beach · Bali',
      curatedByGemini: true,
      lat: -8.8292,
      lng: 115.0869,
    ),
    const ExplorePin(
      id: 'e4',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      locationLabel: 'Santorini Caldera · Greece',
      curatedByGemini: false,
      lat: 36.3492,
      lng: 25.4422,
    ),
    const ExplorePin(
      id: 'e5',
      imageUrl: 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=800',
      locationLabel: 'Hagia Sophia · Istanbul',
      curatedByGemini: true,
      lat: 41.0086,
      lng: 28.9802,
    ),
    const ExplorePin(
      id: 'e6',
      imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800',
      locationLabel: 'Colosseum · Rome',
      curatedByGemini: false,
      lat: 41.8902,
      lng: 12.4922,
    ),
  ];

  static final List<LocalPin> local = [
    const LocalPin(
      id: 'l1',
      imageUrl: 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=800',
      title: 'Galata Tower Viewpoint',
      distanceKm: '0.8 km away',
      lat: 41.0256,
      lng: 28.9744,
    ),
    const LocalPin(
      id: 'l2',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
      title: 'Secret Sourdough Bakery · Kadıköy',
      distanceKm: '1.2 km away',
      lat: 40.9922,
      lng: 29.0245,
    ),
    const LocalPin(
      id: 'l3',
      imageUrl: 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800',
      title: 'Grand Bazaar · Kapalıçarşı',
      distanceKm: '2.1 km away',
      lat: 41.0106,
      lng: 28.9682,
    ),
    const LocalPin(
      id: 'l4',
      imageUrl: 'https://images.unsplash.com/photo-1570939272193-9f9e2b1a4b8e?w=800',
      title: 'Bosphorus Sunset Spot',
      distanceKm: '3.0 km away',
      lat: 41.0390,
      lng: 29.0090,
    ),
    const LocalPin(
      id: 'l5',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
      title: 'Spice Bazaar · Mısır Çarşısı',
      distanceKm: '1.8 km away',
      lat: 41.0167,
      lng: 28.9708,
    ),
  ];

  static List<FollowingPost> getFollowing() => List.from(following);
  static List<ExplorePin> getExplore() => List.from(explore);
  static List<LocalPin> getLocal() => List.from(local);
}
