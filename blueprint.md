# Battle Master - App Blueprint

## 1. Overview

Battle Master is a mobile gaming application designed for competitive players. It allows users to register, participate in tournaments, and manage their profiles. The app is built with Flutter and uses Supabase for the backend.

## 2. Style and Design

*   **Theme:** Modern, gaming-centric dark theme.
*   **Primary Colors:** Dark Charcoal (`#1a202c`) as the background and a vibrant Gold (`#facc15`) as the accent color.
*   **UI:** Clean, consistent, and intuitive user interface with clear navigation.
*   **Iconography:** Material Design icons are used to enhance clarity.
*   **Typography:** Bold and clear fonts with shadows for emphasis on titles.

## 3. Implemented Features

### Authentication
*   **User Registration:** Users can create a new account using their `Username`, `Mobile Number`, `Email`, and `Password`. An optional `Referral Code` can be provided.
*   **User Login:** Login is based on `Email` and `Password`.
*   **Navigation:** Seamless navigation between Login and Register screens.

### Database (`users` table)
*   The `public.users` table stores essential user information, including referral data.

### Global Maintenance Mode
*   **Purpose**: Allows administrators to put the entire application into a maintenance state in real-time.
*   **Control Mechanism**:
    *   A `app_config` table in Supabase with a single row.
    *   A boolean column `is_maintenance_on` acts as the master switch.
*   **Real-time Functionality**:
    *   The app listens to live changes in the `app_config` table using Supabase Realtime.
    *   If `is_maintenance_on` is set to `true`, all active users are immediately forced to a dedicated `MaintenanceScreen`.
    *   If `is_maintenance_on` is set to `false`, the app navigates users to the `LoginScreen` to restart their session.
*   **Implementation Files**:
    *   `lib/screens/maintenance_screen.dart`: The UI for the maintenance notice.
    *   `lib/main.dart`: Contains the core logic for listening to the switch and handling navigation.

## 4. Security Enhancements

### Environment Variables for API Keys
*   **Purpose**: To secure sensitive API keys and prevent them from being hardcoded in the source code.
*   **Implementation**:
    *   The `flutter_dotenv` package has been integrated.
    *   A `.env` file was created at the project root to store `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
    *   `main.dart` was updated to load these keys from the `.env` file at runtime.

## 5. Current Task: Implement Global Maintenance Mode (Completed)

### Plan and Steps

1.  **Database Setup**:
    *   **Action**: An SQL migration was run on the Supabase project.
    *   **Change**: Created the `app_config` table with an `is_maintenance_on` boolean column and enabled Row Level Security and Realtime.

2.  **UI Creation**:
    *   **Action**: Created a new file `lib/screens/maintenance_screen.dart`.
    *   **Change**: Implemented a user-friendly screen informing the user about the ongoing maintenance.

3.  **Security & Configuration**:
    *   **Action**: Added the `flutter_dotenv` package and created a `.env` file.
    *   **Change**: To manage Supabase URL and anon key securely, separating them from the source code.

4.  **Core Logic Implementation**:
    *   **Action**: Heavily modified `lib/main.dart`.
    *   **Changes**:
        *   Integrated `flutter_dotenv` to securely load Supabase keys.
        *   Implemented a `GlobalKey<NavigatorState>` for app-wide navigation control.
        *   Added logic to check the maintenance status on app startup.
        *   Subscribed to the `app_config` table using Supabase Realtime to listen for live changes.
        *   Created logic to force-navigate users to `MaintenanceScreen` or `LoginScreen` based on the realtime updates.

5.  **Bug Fixes**:
    *   **Action**: Corrected the Supabase Realtime callback function signature in `main.dart`.
    *   **Change**: The function was changed from `(payload, [ref])` to the correct `(payload)`, resolving a runtime error.

### Final Outcome
The application now has a robust, secure, and real-time maintenance mode system. All sensitive keys are also secured outside of the version-controlled source code, following best practices.
