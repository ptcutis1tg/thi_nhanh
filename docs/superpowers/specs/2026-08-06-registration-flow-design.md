# Registration Flow & UI Update Design

## 1. Overview
This design outlines the implementation of a new Registration (Sign Up) flow in the `Thi Nhanh` application. The registration will be integrated directly into the existing `GreetingScreen` using a modern sliding tab interface, keeping the user experience seamless and contained within a single screen.

## 2. UI/UX Design
- **Container Layout**: The authentication section on the right side of the `GreetingScreen` will be encapsulated within a distinct, styled `Container`.
- **Sliding Navigation**: Inside the top of this container, a custom navigation bar (e.g., a custom `TabBar` or Segmented Control) will be added with two options: **"Đăng nhập"** (Login) and **"Đăng ký"** (Register).
- **Form Transition**: Clicking on "Đăng ký" will trigger a sliding animation (using `PageView` or `TabBarView`) to transition the view from the Login form to the Register form.
- **Register Form Fields**:
  - Họ tên (Full Name)
  - Email
  - Mật khẩu (Password)
  - Xác nhận mật khẩu (Confirm Password)
- **Buttons**: The Register form will have an "Đăng ký" button. The Google login option can be kept on the Login tab or shared below the sliding view, depending on layout constraints (recommended: keep it on the Login tab).

## 3. State Management & Logic
- **AuthProvider Update**: 
  - Add a new method `signUpWithEmail(String email, String password, String fullName)`.
  - This method will call `Supabase.instance.client.auth.signUp()`, passing the `email`, `password`, and storing the `fullName` in the user's `data` metadata.
- **Post-Registration Flow**:
  - Upon successful registration, the application will automatically slide the view back to the **"Đăng nhập"** tab.
  - A success `SnackBar` will be displayed: *"Đăng ký thành công! Vui lòng đăng nhập."*
  - The Email field in the Login form can optionally be pre-filled with the newly registered email.

## 4. Error Handling & Validation
- **Client-Side Validation**:
  - Ensure all fields are filled.
  - Validate email format.
  - Ensure Password and Confirm Password match.
- **Server-Side Errors**: Catch and display any errors returned by Supabase (e.g., email already exists) using a red `SnackBar`.
