# TrueUp Lite Flutter App

A Flutter mobile application for managing order suggestions and purchase orders, integrated with the TrueUp Lite backend API.

## Features

### Order Suggestions Management
- **Generate Order Suggestions**: Automatically generate purchase recommendations based on stock levels and reorder points
- **Supplier-wise Grouping**: View suggestions organized by suppliers
- **Product Details**: View detailed product information including current stock, minimum thresholds, and suggested quantities
- **Quantity Adjustments**: Modify suggested quantities before creating purchase orders

### Purchase Order Basket
- **Basket Management**: Add, remove, and update items in your purchase basket
- **Supplier Grouping**: View basket items grouped by suppliers
- **Bulk Operations**: Add multiple items to basket at once
- **Create Purchase Orders**: Generate purchase orders directly from basket items

### History & Analytics
- **Order History**: View past order suggestions with detailed information
- **Weekly Purchase History**: Analyze purchase patterns over time
- **Statistics**: Get insights into ordering patterns and costs

### Export Capabilities
- **Excel Export**: Export order suggestions to Excel format
- **PDF Export**: Generate PDF reports of order suggestions
- **Text Export**: Export data in simple text format

## Architecture

### State Management
- **Riverpod**: Used for state management and dependency injection
- **Provider Pattern**: Clean separation of business logic and UI

### API Integration
- **HTTP Client**: RESTful API integration with the TrueUp Lite backend
- **Error Handling**: Comprehensive error handling and user feedback
- **Offline Support**: Graceful handling of network issues

### UI/UX
- **Material Design 3**: Modern, consistent UI following Material Design guidelines
- **Responsive Layout**: Optimized for different screen sizes
- **Loading States**: Clear feedback during data loading
- **Error States**: User-friendly error messages and retry options

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── models/                             # Data models
│   ├── supplier_order_suggestion.dart
│   ├── product_order_suggestion.dart
│   ├── po_basket_item.dart
│   ├── order_suggestion_history.dart
│   ├── weekly_purchase_history.dart
│   ├── request_models.dart
│   └── response_models.dart
├── providers/                          # State management
│   └── order_suggestions_provider.dart
├── screens/                           # UI screens
│   ├── home_screen.dart
│   └── order_suggestions/
│       ├── order_suggestions_screen.dart
│       ├── order_suggestions_basket_screen.dart
│       ├── order_suggestions_history_screen.dart
│       └── weekly_purchase_history_screen.dart
└── services/                          # API services
    └── api_service.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- TrueUp Lite Backend running (for API integration)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd trueup-lite-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (for JSON serialization)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure API endpoint**
   
   Update the `baseUrl` in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://your-backend-url:8080';
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Backend Integration

The app expects the TrueUp Lite backend to be running with the following endpoints available:

- `GET /order-suggestions/generate` - Generate order suggestions
- `POST /order-suggestions/basket/add` - Add items to basket
- `GET /order-suggestions/basket` - Get basket items
- `POST /order-suggestions/basket/create-po` - Create purchase orders
- `GET /order-suggestions/history` - Get order history
- `GET /order-suggestions/weekly-purchase-history` - Get weekly history

## Configuration

### Environment Configuration
Update the API base URL in `lib/services/api_service.dart` to point to your backend server:

```dart
static const String baseUrl = 'http://localhost:8080'; // Change this
```

### Build Configuration
The app is configured for Android builds. For iOS builds, additional configuration may be required.

## Key Features Implementation

### Order Suggestions Screen
- Displays supplier-wise order suggestions
- Shows product details with stock information
- Allows adding items to basket
- Supports bulk operations

### Basket Management
- Real-time basket updates
- Supplier grouping
- Item quantity modifications
- Purchase order creation

### History Tracking
- Paginated order history
- Weekly purchase analytics
- Detailed action tracking

## API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/order-suggestions/generate` | GET | Generate order suggestions |
| `/order-suggestions/generate-for-suppliers` | POST | Generate for specific suppliers |
| `/order-suggestions/update-quantities` | POST | Update suggested quantities |
| `/order-suggestions/create-purchase-order` | POST | Create purchase order |
| `/order-suggestions/basket/add` | POST | Add item to basket |
| `/order-suggestions/basket/remove/{id}` | DELETE | Remove item from basket |
| `/order-suggestions/basket/update` | PUT | Update basket item |
| `/order-suggestions/basket` | GET | Get basket items |
| `/order-suggestions/basket/clear` | DELETE | Clear basket |
| `/order-suggestions/basket/create-po` | POST | Create PO from basket |
| `/order-suggestions/basket/add-suggestion` | POST | Add suggestion to basket |
| `/order-suggestions/basket/add-multiple-suggestions` | POST | Add multiple suggestions |
| `/order-suggestions/basket/grouped` | GET | Get grouped basket items |
| `/order-suggestions/history` | GET | Get order history |
| `/order-suggestions/weekly-purchase-history` | GET | Get weekly history |
| `/order-suggestions/statistics` | GET | Get statistics |
| `/order-suggestions/export-excel` | POST | Export to Excel |
| `/order-suggestions/export-pdf` | POST | Export to PDF |
| `/order-suggestions/export-text` | POST | Export to text |

## Development

### Code Generation
The app uses JSON serialization. After modifying model classes, run:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Adding New Features
1. Create/update models in `lib/models/`
2. Add API methods in `lib/services/api_service.dart`
3. Update providers in `lib/providers/`
4. Create/update UI screens in `lib/screens/`

### Testing
```bash
flutter test
```

## Build & Deployment

### Android
```bash
flutter build apk --release
```

### iOS (requires macOS and Xcode)
```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues

1. **API Connection Issues**
   - Check if backend is running
   - Verify API base URL configuration
   - Check network connectivity

2. **Build Issues**
   - Run `flutter clean` and `flutter pub get`
   - Regenerate code with build_runner
   - Check Flutter and Dart SDK versions

3. **State Management Issues**
   - Check provider configurations
   - Verify data flow in Riverpod providers
   - Check for proper error handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of the TrueUp Lite application suite.
