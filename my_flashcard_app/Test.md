# Kết quả kiểm thử và kiểm định
Lệnh chạy test: flutter test test/unit --reporter expanded --concurrency=1
## Tóm tắt

- **Unit/widget tests:** đạt, 32 bài kiểm thử.
- **Static analysis:** đạt, không có lỗi.
- **Định dạng Dart:** đạt, không có file cần định dạng lại.
- **Firebase thật / Firebase Emulator:** chưa kiểm thử; các bài kiểm thử tài khoản và đồng bộ dùng đối tượng giả.

## Danh sách test và kết quả từng test

Kết quả bên dưới là lần chạy `flutter test` gần nhất: **32/32 test đạt, 0 test thất bại**.

### SRS, mô hình dữ liệu và kho từ

| # | File / test case | Kiểm tra | Kết quả |
|---:|---|---|---|
| 1 | `models_test.dart` — `new words are immediately due and not mastered` | Từ mới ở hộp 0, đến hạn ngay và chưa thành thạo. | Đạt |
| 2 | `models_test.dart` — `all ratings update the box and interval as specified` | Bốn mức Again/Hard/Good/Easy cập nhật hộp và lịch ôn đúng. | Đạt |
| 3 | `models_test.dart` — `ratings respect minimum and maximum boxes` | Hộp không giảm dưới 0 hoặc vượt mức tối đa. | Đạt |
| 4 | `models_test.dart` — `mastery and due checks use their documented boundaries` | Kiểm tra biên của thành thạo và thời điểm đến hạn. | Đạt |
| 5 | `models_test.dart` — `progress round-trips through JSON` | Tiến độ giữ nguyên hộp và ngày ôn sau khi mã hóa/đọc JSON. | Đạt |
| 6 | `models_test.dart` — `vocabulary and app languages parse supported and unknown codes` | Đọc mã ngôn ngữ từ vựng/ngôn ngữ giao diện và giá trị không hỗ trợ. | Đạt |
| 7 | `models_test.dart` — `avatar lookup falls back safely for unknown identifiers` | Tìm avatar hợp lệ và dùng avatar mặc định với ID lạ/null. | Đạt |
| 8 | `models_test.dart` — `privacy mode defaults to cloaked for unknown values` | Chế độ riêng tư không hợp lệ mặc định về Cloaked. | Đạt |
| 9 | `models_test.dart` — `public progress parses complete and incomplete documents` | Đọc thống kê đầy đủ, mặc định cho dữ liệu thiếu/sai và tính trung bình. | Đạt |
| 10 | `vocab_repository_test.dart` — `loads manifest decks and vocabulary assets with unique word IDs` | Nạp bộ thẻ/từ từ assets; kiểm tra dữ liệu hợp lệ và ID không trùng. | Đạt |

### Bài kiểm tra từ vựng

| # | File / test case | Kiểm tra | Kết quả |
|---:|---|---|---|
| 11 | `exam_logic_test.dart` — `computes per-deck counts and rejects invalid percentages` | Tính số từ theo phần trăm và từ chối tỷ lệ ngoài 0–100. | Đạt |
| 12 | `exam_logic_test.dart` — `selects only requested decks and shuffles a bounded sample` | Chỉ lấy từ ở bộ được chọn, đúng số lượng và không trùng từ. | Đạt |
| 13 | `exam_logic_test.dart` — `empty deck selection produces no questions` | Không tạo câu hỏi khi chưa chọn bộ thẻ. | Đạt |
| 14 | `exam_logic_test.dart` — `accepts any exact comma-separated meaning ignoring case/spacing` | Chấp nhận một nghĩa đúng, không phân biệt hoa/thường và khoảng trắng. | Đạt |
| 15 | `exam_logic_test.dart` — `rejects empty and partial answers` | Từ chối đáp án rỗng, chỉ khớp một phần hoặc có ký tự thừa. | Đạt |

### Tài khoản và trạng thái ứng dụng

| # | File / test case | Kiểm tra | Kết quả |
|---:|---|---|---|
| 16 | `auth_service_test.dart` — `registers email account and reserves the display name` | Đăng ký email và đặt tên hiển thị cho UID. | Đạt |
| 17 | `auth_service_test.dart` — `signs in using the supplied email and password` | Gửi email/mật khẩu đến thao tác đăng nhập. | Đạt |
| 18 | `auth_service_test.dart` — `links email credentials to an existing guest user` | Liên kết email vào tài khoản khách hiện tại, giữ UID và tên. | Đạt |
| 19 | `auth_service_test.dart` — `releases the reserved name when guest linking fails` | Khi liên kết thất bại, khôi phục tên cũ và giải phóng tên mới. | Đạt |
| 20 | `auth_service_test.dart` — `requires confirmation and deletes linked cloud data on unlink` | Sai tên xác nhận không xóa tài khoản; xác nhận đúng thì xác thực lại và xóa dữ liệu cloud. | Đạt |
| 21 | `auth_service_test.dart` — `classifies providerless users as guests and translates auth errors` | Nhận diện tài khoản khách và chuyển mã lỗi đăng nhập thành thông báo. | Đạt |
| 22 | `app_state_test.dart` — `starts a guest session and persists SRS progress on device` | Tạo phiên khách, tự đánh giá từ và lưu tiến độ local. | Đạt |
| 23 | `app_state_test.dart` — `restores a saved guest session after signing out` | Tiếp tục phiên khách đã lưu và khôi phục tên/tiến độ. | Đạt |
| 24 | `app_state_test.dart` — `saves vocabulary language and application language separately` | Lưu riêng ngôn ngữ học và ngôn ngữ giao diện. | Đạt |
| 25 | `app_state_test.dart` — `stores guest avatar locally and rejects unknown avatar IDs` | Lưu avatar khách trên thiết bị và báo lỗi với ID không hợp lệ. | Đạt |
| 26 | `app_state_test.dart` — `updates and persists a guest display name` | Đổi tên khách và xác nhận tên mới được lưu local. | Đạt |
| 27 | `app_state_test.dart` — `validates and stores quiz results for a guest` | Lưu thống kê bài kiểm tra khách và từ chối kết quả sai quy tắc. | Đạt |

### Giao diện

| # | File / test case | Kiểm tra | Kết quả |
|---:|---|---|---|
| 28 | `account_dialogs_test.dart` — `privacy dialog saves restricted viewer names` | Chọn Restricted, nhập danh sách người xem và nhận lại cài đặt đã lưu. | Đạt |
| 29 | `account_dialogs_test.dart` — `link dialog validates input and returns account details` | Báo lỗi khi thiếu dữ liệu; trả về tên/email/mật khẩu khi hợp lệ. | Đạt |
| 30 | `ui_flow_test.dart` — `reveals a flashcard and saves the selected rating` | Lật flashcard, chọn mức nhớ và xác nhận hộp SRS được cập nhật. | Đạt |
| 31 | `ui_flow_test.dart` — `selects a deck, grades an answer, and shows quiz results` | Chọn bộ, trả lời đúng, chuyển đến kết quả và ghi nhận thống kê. | Đạt |
| 32 | `widget_test.dart` — `application opens the study shell for a local guest` | Khởi chạy ứng dụng với khách local và hiển thị màn học/thanh điều hướng. | Đạt |

## Lệnh kiểm tra đã chạy

| Lệnh | Kết quả |
|---|---|
| `flutter test` | Thành công: tất cả 32 bài kiểm thử đều đạt. |
| `flutter analyze lib test` | Thành công: `No issues found!`. |
| `dart format --set-exit-if-changed lib\models\exam_logic.dart lib\pages\exam_page.dart test` | Thành công: không phát hiện thay đổi định dạng. |
| `git -c core.whitespace=cr-at-eol diff --check` | Thành công: không có lỗi whitespace trong diff (xử lý đúng CRLF trên Windows). |

## Phạm vi kiểm thử

### Logic và dữ liệu

- SRS/Leitner: tiến độ mới, trạng thái đến hạn, mức thành thạo, bốn mức đánh giá, giới hạn hộp và chuyển đổi JSON.
- Bài kiểm tra: tính số từ theo tỷ lệ, kiểm tra tỷ lệ không hợp lệ, chỉ lấy từ trong bộ đã chọn, lấy mẫu ngẫu nhiên và đối chiếu câu trả lời.
- Mô hình dữ liệu: mã ngôn ngữ, chế độ riêng tư, ảnh đại diện và đọc thống kê công khai đầy đủ/thiếu dữ liệu.
- Kho từ vựng: nạp manifest và assets, kiểm tra bộ thẻ, từ vựng và ID duy nhất.

### Tài khoản và trạng thái ứng dụng

- Đăng ký, đăng nhập và liên kết tài khoản email.
- Khôi phục tên hiển thị khi thao tác liên kết thất bại.
- Hủy liên kết: yêu cầu xác nhận tên, xác thực lại, xóa dữ liệu cloud và giải phóng tên.
- Chuyển thông báo lỗi Firebase Authentication sang nội dung dễ hiểu.
- Khách cục bộ: tạo/tiếp tục phiên, lưu/khôi phục tiến độ, đổi tên, đổi ảnh đại diện và đổi ngôn ngữ.
- Kiểm tra tính hợp lệ và lưu kết quả bài kiểm tra.

### Giao diện

- Mở ứng dụng ở chế độ khách và hiển thị thanh điều hướng.
- Lật flashcard, đánh giá mức ghi nhớ và xác nhận tiến độ được cập nhật.
- Chọn bộ thẻ, trả lời bài kiểm tra và xem màn hình kết quả.
- Hộp thoại thiết lập riêng tư và biểu mẫu liên kết tài khoản, gồm kiểm tra dữ liệu nhập.

## Trường hợp lỗi đã kiểm tra

- Tỷ lệ số từ của bài kiểm tra nhỏ hơn 0 hoặc lớn hơn 100.
- Câu trả lời trống, không chính xác hoặc chỉ khớp một phần nghĩa.
- Ảnh đại diện không tồn tại.
- Mã ngôn ngữ hoặc chế độ quyền riêng tư không xác định.
- Từ chối hủy liên kết nếu tên xác nhận không khớp.
- Khôi phục tên và dữ liệu đặt trước khi liên kết email gặp lỗi.
- Kết quả bài kiểm tra có số lượng từ/đáp án sai quy tắc.

## Giới hạn và kiểm thử tiếp theo

- Các bài kiểm thử Firebase dùng fake/mock, không chứng minh quyền truy cập, dữ liệu hoặc cấu hình Firebase đang chạy đúng trên dự án thật. Nên chạy thêm integration test với Firebase Emulator cho Authentication, Firestore, quy tắc riêng tư, đồng bộ và xóa dữ liệu.
- Widget tests chạy bằng Flutter test binding, chưa chạy trên thiết bị/emulator Android hoặc iOS. Cần kiểm tra thủ công hoặc bổ sung integration test trên từng nền tảng để xác nhận bố cục, bàn phím, cuộn và thao tác cảm ứng trên thiết bị thật.
- Chưa có kiểm thử tự động riêng cho toàn bộ các màn hình/luồng tra cứu hồ sơ công khai, đổi mật khẩu và hủy liên kết qua UI.
- Những kết quả trên áp dụng cho các lệnh và mã nguồn tại thời điểm ghi nhận; cần chạy lại `flutter test` và `flutter analyze lib test` sau các thay đổi tiếp theo.
