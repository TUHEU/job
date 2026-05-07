# JobMatch Cameroon

A Flutter mobile application for job matching platform in Cameroon, connecting job seekers with employers.

## Features

- **User Authentication**: JWT-based login and registration for job seekers and employers
- **Job Posting**: Employers can post jobs with detailed requirements
- **Job Browsing**: Job seekers can browse and search for jobs
- **CV Upload**: File upload functionality for job seekers to submit their CVs
- **Smart Matching**: AI-powered job recommendations based on skills
- **Application Management**: Track job applications and manage hiring process

## Project Structure

```
lib/
├── models/           # Data models (User, Job, Application)
├── providers/        # State management (AuthProvider)
├── services/         # API services (ApiService)
├── screens/          # UI screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── job_list_screen.dart
│   ├── post_job_screen.dart
│   ├── applications_screen.dart
│   ├── matches_screen.dart
│   └── profile_screen.dart
└── main.dart         # App entry point
```

## Backend

The app requires a Node.js backend server. See the `../backend/` directory for the server implementation.

## Setup Instructions

### Prerequisites

- Flutter SDK (3.10.7 or later)
- Dart SDK
- Node.js (for backend)
- Android Studio or VS Code with Flutter extensions

### Installation

1. **Clone or navigate to the project directory**
   ```bash
   cd job_app
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Start the backend server**
   ```bash
   cd ../backend
   npm install
   node server.js
   ```

4. **Run the Flutter app**
   ```bash
   cd ../job_app
   flutter run
   ```

### Backend Setup

The backend server runs on `http://localhost:3000` by default. Make sure to update the `baseUrl` in `lib/services/api_service.dart` if needed.

## Usage

1. **Register**: Create an account as either a job seeker or employer
2. **Login**: Use your credentials to access the app
3. **Job Seekers**:
   - Browse and search for jobs
   - Upload your CV
   - Apply for jobs
   - View your matches
4. **Employers**:
   - Post new job opportunities
   - View and manage applications
   - Accept or reject candidates

## Dependencies

- `http`: For API calls
- `shared_preferences`: Local data storage
- `provider`: State management
- `file_picker`: File selection for CV uploads
- `http_parser`: Multipart file uploads

## API Endpoints

- `POST /register` - User registration
- `POST /login` - User authentication
- `GET /jobs` - Get all jobs
- `POST /jobs` - Post a new job
- `POST /apply` - Apply for a job
- `GET /applications` - Get applications (employer)
- `PUT /applications/:id` - Update application status
- `GET /matches` - Get job matches (job seeker)
- `POST /upload-cv` - Upload CV file

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

This project is licensed under the MIT License.
