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
*   **User Registration:**
    *   Users can create a new account using their `Username`, `Mobile Number`, `Email`, and `Password`.
    *   **New:** An optional `Referral Code` field has been added.
    *   All mandatory fields are validated.
    *   Password confirmation is required.
    *   Upon successful registration, a new user record is created in the `users` table.
    *   The `referred_by` column is populated if a referral code was provided.
    *   A unique referral code for the new user is generated and stored in the `fcode` column.
    *   A verification email is sent to the user.
*   **User Login:**
    *   Login is strictly based on `Email` and `Password`.
    *   The option to log in with a mobile number has been removed to simplify the process and improve reliability.
*   **Navigation:**
    *   Seamless navigation between Login and Register screens.

### Database (`users` table)
*   The `public.users` table stores essential user information.
*   It now includes `mobile` and `email` columns to store the respective user data upon registration.

## 4. Current Task: Add Optional Referral Code to Registration

### Plan and Steps

1.  **UI Enhancement:**
    *   **Action:** Modify `lib/screens/register_screen.dart`.
    *   **Change:** Added a new `TextEditingController` (`_referralCodeController`) and a new input field in the UI for the referral code, placed below the confirm password field. The field is labeled "Referral Code (Optional)".
2.  **Logic Implementation:**
    *   **Action:** Updated the `_register` method.
    *   **Change:** The value from the referral code input is retrieved. When inserting the new user data into the `users` table, a ternary check is performed: `referralCode.isNotEmpty ? referralCode : null`. This saves the provided code or `null` if the field is empty.
3.  **Documentation Update:**
    *   **Action:** Update the `blueprint.md` file to reflect this new feature.
    *   **Change:** The "Implemented Features" and "Current Task" sections were updated to include details about the new optional referral code system.

4.  **Final Outcome:** The registration process now supports an optional referral code, allowing for user acquisition tracking and rewards, without complicating the core registration flow.
