# FinFlow
FinFlow is a personal finance management application on the Flutter platform, helping users record income and expenses and control budgets effectively according to the 50/30/20 rule. With Offline-first architecture using SQLite, the application ensures fast processing speed, operates without the need for a network.
<div align="center">

# 💸 FinFlow: Quản Lý Chi Tiêu Cá Nhân

**Đồ án Chuyên ngành Lập trình Mobile - Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)
[![SQLite](https://img.shields.io/badge/SQLite-Local_DB-003B57?logo=sqlite)](https://pub.dev/packages/sqflite)
[![Firebase](https://img.shields.io/badge/Firebase-Auth_&_Sync-FFCA28?logo=firebase)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Giới thiệu](#-giới-thiệu) • [Tính năng](#-tính-năng) • [Công nghệ](#-công-nghệ) • [Cài đặt](#-cài-đặt) • [Thành viên](#-thành-viên-nhóm)

</div>

---

## 📖 Giới thiệu (Introduction)

**FinFlow** là giải pháp quản lý tài chính cá nhân toàn diện trên di động. Dự án được xây dựng nhằm giải quyết vấn đề khó khăn trong việc theo dõi dòng tiền hàng ngày, giúp người dùng hình thành thói quen ghi chép và kiểm soát chi tiêu thông minh.

Ứng dụng kết hợp sức mạnh của **Flutter** cho giao diện mượt mà, **SQLite** cho lưu trữ ngoại tuyến tin cậy và **Firebase** cho các tính năng xác thực bảo mật.

---

## ✨ Tính năng Chính (Key Features)

### 1. 🔐 Xác thực & Bảo mật (Authentication)
* **Đăng nhập đa phương thức:** Email/Password, Google, Apple.
* **Bảo mật:** Tùy chọn khóa ứng dụng bằng mật khẩu/vân tay (trong phần Cài đặt).
* **Quản lý tài khoản:** Cập nhật thông tin cá nhân (Avatar, Tên, Ngày sinh).

### 2. 💸 Quản lý Thu Chi (Transaction Management)
* **Thêm giao dịch thông minh:** Tích hợp bàn phím máy tính (Calculator) ngay trên màn hình nhập liệu.
* **Phân loại đa dạng:**
    * **Chi tiêu:** Ăn uống, Di chuyển, Hóa đơn, Mua sắm, Giải trí, Sức khỏe...
    * **Thu nhập:** Tiền lương, Thưởng, Làm thêm, Được trả nợ...
* **Ghi chú & Thời gian:** Đính kèm ghi chú chi tiết và chọn ngày giao dịch linh hoạt.

### 3. 📊 Tổng quan & Báo cáo (Dashboard & Reports)
* **Dashboard:** Xem số dư hiện tại, tổng thu/chi trong ngày.
* **Lịch (Calendar View):** Xem lại lịch sử giao dịch theo từng ngày trên lịch.
* **Thống kê:** Biểu đồ trực quan hóa dòng tiền (đang phát triển).

---

## 🏗️ Kiến trúc Hệ thống (Architecture) 

🗄️ Database Schema (SQLite)
Bảng Transactions | Field | Type | Description | | :--- | :--- | :--- | | id | INTEGER PK | ID tự tăng | | amount | REAL | Số tiền | | note | TEXT | Ghi chú | | date | TEXT | Ngày giao dịch (ISO8601) | | type | TEXT | 'income' / 'expense' | | category_id| INTEGER FK | Liên kết bảng Categories |
Bảng Categories | Field | Type | Description | | :--- | :--- | :--- | | id | INTEGER PK | ID tự tăng | | name | TEXT | Tên danh mục (vd: Ăn uống) | | icon | TEXT | Đường dẫn icon | | group | TEXT | Nhóm (Thiết yếu, Cá nhân...)

🚀 Công nghệ & Thư viện (Tech Stack)
Core: Flutter SDK, Dart Language.
Local Database: sqflite, path_provider (Lưu trữ giao dịch offline).
Backend Services: firebase_auth, firebase_core (Đăng nhập).
State Management: provider (hoặc flutter_bloc / get).
UI/UX: intl (Định dạng tiền tệ/ngày tháng), fl_chart (Biểu đồ), font_awesome_flutter (Icons).

⚡ Hướng dẫn Cài đặt (Installation)
Clone dự án:
Bash
git clone [https://github.com/username/finflow-project.git](https://github.com/username/finflow-project.git)
Cài đặt dependencies:
Bash
flutter pub get
### Back-end & Database
| Công nghệ | Phiên bản | Mục đích |
| :--- | :--- | :--- |
| **SQLite (sqflite)** | `^2.4.2` | Lưu trữ dữ liệu giao dịch cục bộ (Offline-first). |
| **Firebase Auth** | `^6.1.2` | Xác thực người dùng (Login/Register). |
| **Firebase Core** | `^4.2.1` | Nền tảng kết nối Firebase. |
| **Path Provider** | `^2.1.5` | Tìm đường dẫn hệ thống để lưu file DB. |

### Front-end & UI
| Công nghệ | Phiên bản | Mục đích |
| :--- | :--- | :--- |
| **Flutter** | 3.x | Framework phát triển đa nền tảng (Android Focus). |
| **Provider** | `^6.1.5` | Quản lý trạng thái (State Management). |
| **Intl** | `^0.20.2` | Định dạng tiền tệ (VND) và Ngày tháng. |
| **FL Chart** | `^1.1.1` | Vẽ biểu đồ thống kê thu chi. |
| **Font Awesome** | `^10.12.0`| Bộ icon chuyên nghiệp bổ trợ. |
| **Google Fonts** | `^6.3.3` | Font chữ đẹp cho ứng dụng. |
| **Http** | `^1.6.0` | Gọi API (nếu cần mở rộng sau này). |
Cấu hình Firebase:
Thêm google-services.json vào android/app/.
Thêm GoogleService-Info.plist vào ios/Runner/.
Chạy ứng dụng:
Bash
flutter run

👥 Phân công & Quản lý Dự án
* Thành viên: [Phùng Đức Tín - Leader]
 Vai trò: Fullstack Core & Logic
 Nhiệm vụ chi tiết:
- Quản lý GitHub Repo, Merge Code
- Xây dựng DatabaseHelper (SQLite Core)
- Viết logic xử lý dữ liệu phức tạp (tính toán số dư, tổng thu chi)
- Xử lý logic màn hình Chi tiết giao dịch (Sửa/Xóa)
 Nhánh Git: main, feature/backend-logic

* Thành viên: []
 Vai trò: Frontend (Main UI)
 Nhiệm vụ chi tiết:
- Thiết kế màn hình Dashboard (Trang chủ)
- Xây dựng màn hình Thêm Giao Dịch (Add Transaction)
- Tùy biến widget nhập tiền và chọn danh mục
- Quản lý giao diện Danh mục (Thêm/Sửa danh mục)
 Nhánh Git: ui/dashboard-enhancement, ui/add-transaction

* Thành viên: [Thành viên 3]
 Vai trò: Features (Auth & Stats)
 Nhiệm vụ chi tiết:
- Xây dựng màn hình Đăng nhập / Đăng ký
- Tích hợp Firebase Authentication
- Xây dựng màn hình Báo cáo thống kê (Biểu đồ)
- Màn hình Cài đặt (Đổi ngôn ngữ, Nhắc nhở)
 Nhánh Git: feature/auth-login, feature/reports-settings
<div align="center">

🤝 Quy tắc làm việc nhóm (Git Flow)
Để đảm bảo code không bị xung đột, các thành viên vui lòng tuân thủ:
KHÔNG code trực tiếp trên nhánh main.

Mỗi khi bắt đầu tính năng mới, hãy tạo nhánh từ main:
Bash
git checkout main
git pull origin main
git checkout -b [ten-nhanh-cua-ban]

Commit thường xuyên với nội dung rõ ràng:
feat: Thêm màn hình đăng nhập
fix: Sửa lỗi hiển thị ngày tháng
ui: Cập nhật màu sắc dashboard
Sau khi hoàn thành, đẩy code lên và tạo Pull Request (PR) để Leader review.

Developed with ❤️ by FinFlow Team
</div>



