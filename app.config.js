module.exports = {
  expo: {
    name: 'CheapestGo',
    slug: 'no-001-cheapestgo',
    version: '1.0.0',
    orientation: 'portrait',
    icon: './assets/images/icon.png',
    scheme: 'mobileapp',
    userInterfaceStyle: 'light',
    newArchEnabled: true,
    splash: {
      image: './assets/images/splash-icon.png',
      resizeMode: 'contain',
      backgroundColor: '#ffffff',
    },
    ios: {
      supportsTablet: true,
      bundleIdentifier: 'com.cheapestgo.mobile',
    },
    android: {
      package: 'com.cheapestgo.mobile',
      adaptiveIcon: {
        foregroundImage: './assets/images/adaptive-icon.png',
        backgroundColor: '#ffffff',
      },
      predictiveBackGestureEnabled: false,
    },
    web: {
      bundler: 'metro',
      output: 'static',
      favicon: './assets/images/favicon.png',
    },
    plugins: [
      'expo-router',
      'expo-localization',
      [
        'expo-notifications',
        {
          icon: './assets/images/icon.png',
          color: '#f3f3f3',
          sounds: [],
        },
      ],
      [
        './node_modules/@stripe/stripe-react-native/app.plugin.js',
        {
          merchantIdentifier: 'com.cheapestgo.mobile',
          enableGooglePay: true,
        },
      ],
      [
        '@rnmapbox/maps',
        {
          RNMapboxMapsImpl: 'mapbox',
        },
      ],
      'expo-font',
      'expo-splash-screen',
    ],
    experiments: {
      typedRoutes: true,
    },
    extra: {
      router: {},
      eas: {
        projectId: 'bc166f70-ffc5-4e0e-8f9f-42dc4f0fdf40',
      },
    },
    owner: 'no-001-team-1',

  },
};
