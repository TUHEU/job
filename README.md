# Job & Internship Matching Platform

A mobile app for job seekers and employers to connect, built with Flutter and Node.js backend.

## Features

- User registration and login (Job Seekers and Employers)
- Job posting by employers
- Job browsing and application by job seekers
- Matching system based on skills
- Application management

## Backend Setup

1. Navigate to the `backend` directory.
2. Install dependencies: `npm install`
3. Start the server: `npm start` or `npm run dev`

The backend runs on `http://localhost:3000`.

## Frontend Setup

1. Navigate to the `job` directory (Flutter project).
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

For Android emulator, the API base URL is set to `http://10.0.2.2:3000`.

## Usage

- Register as a job seeker or employer.
- Job seekers can browse jobs, apply, and see matches.
- Employers can post jobs and manage applications.

## OOP Structure

- **User**: Base class for users.
- **JobSeeker**: Inherits from User, has skills and CV.
- **Employer**: Inherits from User, has company.
- **Job**: Represents job listings.
- **Application**: Represents job applications.