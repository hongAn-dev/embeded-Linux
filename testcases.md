# Kịch Bản Kiểm Thử MiniGuard (System Verification Test Cases)

Tài liệu này cung cấp **2 ca kiểm thử (Test Case)** chuẩn, trọng tâm cho từng tính năng cốt lõi của hệ thống **MiniGuard**, giúp bạn dễ dàng chạy và đánh giá nghiệm thu dự án.

---

## 1. Tính năng QEMU Boot & Tối Ưu Hệ Thống (Minimal Specs)
### **Test Case 1.1: Kiểm tra thời gian khởi động & Đăng nhập hệ thống**
- **Mục tiêu:** Xác minh hệ thống boot thành công lên màn hình login dưới 5 giây và đăng nhập được bằng tài khoản cấu hình sẵn.
- **Các bước thực hiện:**
  1. Từ máy Host, chạy script khởi động: `./miniguard/scripts/run.sh`
  2. Bấm giờ từ lúc nhấn Enter đến khi dòng nhắc `miniguard login:` xuất hiện.
  3. Nhập username `root` và password `miniguard123`.
- **Kết quả mong đợi:** 
  - Hệ thống boot hoàn tất lên màn hình đăng nhập trong khoảng 3–5 giây.
  - Đăng nhập thành công và truy cập vào shell `#`.

### **Test Case 1.2: Kiểm tra tính tối giản (Minimal Resource Consumption)**
- **Mục tiêu:** Kiểm chứng hệ thống tiêu thụ RAM và dung lượng lưu trữ cực kỳ thấp (đặc trưng của Embedded Linux).
- **Các bước thực hiện:**
  1. Đăng nhập vào shell của QEMU.
  2. Chạy lệnh kiểm tra bộ nhớ RAM: `free -m`
  3. Chạy lệnh kiểm tra dung lượng ổ đĩa: `df -h`
- **Kết quả mong đợi:**
  - Bộ nhớ RAM tiêu thụ (Used RAM) khi idle **< 20MB** (thường từ 12-16MB).
  - Phân vùng root `/` tiêu thụ dung lượng **< 20MB** (thường từ 12-15MB).

---

## 2. Truy cập SSH (Dropbear SSH Server)
### **Test Case 2.1: Kết nối SSH từ máy Host**
- **Mục tiêu:** Đảm bảo dropbear hoạt động và cho phép đăng nhập an toàn từ xa qua port forwarding.
- **Các bước thực hiện:**
  1. Trên máy Host, mở một terminal mới.
  2. Chạy lệnh kết nối: `ssh -p 2222 root@localhost`
  3. Nhập mật khẩu `miniguard123` khi được yêu cầu.
- **Kết quả mong đợi:** Kết nối thành công, terminal hiển thị banner chào mừng `Welcome to MiniGuard Embedded Linux` và cho phép gõ lệnh.

### **Test Case 2.2: Từ chối các kết nối không đúng mật khẩu**
- **Mục tiêu:** Đảm bảo hệ thống SSH từ chối các truy cập trái phép.
- **Các bước thực hiện:**
  1. Từ máy Host, chạy lệnh: `ssh -p 2222 root@localhost`
  2. Nhập mật khẩu sai (ví dụ: `123456`).
- **Kết quả mong đợi:** Kết nối bị từ chối (`Permission denied, please try again.`), không thể truy cập vào hệ thống.

---

## 3. Giám sát hệ thống (System Monitor Dashboard)
### **Test Case 3.1: Cập nhật tải CPU thời gian thực (Real-time CPU Load)**
- **Mục tiêu:** Xác minh đồ thị/chỉ số CPU trên Dashboard phản ánh đúng trạng thái tải của hệ thống.
- **Các bước thực hiện:**
  1. Mở trình duyệt trên máy Host truy cập `http://localhost:8080` (tab **System**). Quan sát giá trị CPU load khi idle (thường < 5%).
  2. Trên terminal QEMU, chạy lệnh tạo tải giả lập: `dd if=/dev/zero of=/dev/null &` (chạy ngầm).
  3. Quan sát chỉ số CPU Load trên Web Dashboard sau 5 giây.
  4. Tắt tiến trình tải giả lập: `killall dd`
- **Kết quả mong đợi:** 
  - Khi chạy `dd`, CPU Load trên Web tăng vọt lên sát mức 100% (hoặc thanh bar chuyển màu cảnh báo).
  - Khi tắt `dd`, CPU Load nhanh chóng giảm trở lại mức bình thường.

### **Test Case 3.2: Đồng bộ hóa thông số RAM (RAM Metrics Accuracy)**
- **Mục tiêu:** Xác minh thông tin RAM hiển thị trên Dashboard khớp với hệ thống thực tế.
- **Các bước thực hiện:**
  1. Trên terminal QEMU, chạy lệnh: `free` (ghi lại lượng RAM đã dùng).
  2. Trên Web Dashboard (tab **System**), kiểm tra số liệu RAM hiển thị.
- **Kết quả mong đợi:** Thông số RAM Used và RAM Total trên Web Dashboard khớp chính xác (sai lệch không quá 1MB do độ trễ cập nhật) với kết quả lệnh `free`.

---

## 4. Giám sát mạng (Network Monitor)
### **Test Case 4.1: Kiểm tra kết nối Gateway (Ping Status)**
- **Mục tiêu:** Xác minh chức năng tự động kiểm tra trạng thái mạng hoạt động chính xác.
- **Các bước thực hiện:**
  1. Mở Web Dashboard truy cập tab **Network**.
  2. Kiểm tra ô **Gateway** trên Dashboard.
- **Kết quả mong đợi:** Ô Gateway hiển thị trạng thái `✓ Reachable` (hoặc `ok` trong JSON của `cgi-bin/network.sh`) vì QEMU đang kết nối mạng NAT ảo với Host qua Gateway `10.0.2.2`.

### **Test Case 4.2: Cập nhật lưu lượng mạng (Traffic Rx/Tx Counters)**
- **Mục tiêu:** Xác minh chỉ số truyền/nhận dữ liệu mạng thay đổi động khi có lưu lượng đi qua eth0.
- **Các bước thực hiện:**
  1. Truy cập tab **Network** trên Dashboard và ghi lại giá trị **RX** (Received).
  2. Trên terminal QEMU, thực hiện tải một file qua mạng: `wget -O /dev/null http://10.0.2.2:8080/index.html` (hoặc truy cập bất cứ url nội bộ nào để sinh lưu lượng).
  3. Kiểm tra lại giá trị **RX** trên Dashboard.
- **Kết quả mong đợi:** Chỉ số RX tăng lên tương ứng với lượng dữ liệu vừa tải về.

---

## 5. Tường lửa (iptables Firewall)
### **Test Case 5.1: Chặn truy cập cổng cấm (Block Unauthorized Ports)**
- **Mục tiêu:** Đảm bảo chính sách tường lửa chặn toàn bộ truy cập không mong muốn (ngoài cổng 22, 80).
- **Các bước thực hiện:**
  1. Trên máy Host, cố gắng kết nối tới cổng `8888` của QEMU (cổng không được phép): `nc -z -w 2 localhost 8888`
- **Kết quả mong đợi:** Kết nối thất bại (Timeout hoặc Connection Refused), do tường lửa đã DROP gói tin này.

### **Test Case 5.2: Cho phép truy cập cổng dịch vụ (Allow SSH & HTTP)**
- **Mục tiêu:** Đảm bảo tường lửa không chặn nhầm các dịch vụ quan trọng đã được cấu hình cho phép.
- **Các bước thực hiện:**
  1. Kiểm tra kết nối HTTP: `curl -I http://localhost:8080/`
  2. Kiểm tra kết nối SSH: `nc -z -w 2 localhost 2222`
- **Kết quả mong đợi:** Cả hai kết nối đều thành công (HTTP trả về mã `200 OK`, SSH báo cổng mở).

---

## 6. Ghi log bảo mật (Security Log Viewer)
### **Test Case 6.1: Ghi nhận sự kiện chặn (Block Logging in Syslog)**
- **Mục tiêu:** Xác minh khi tường lửa DROP kết nối, kernel ghi nhận sự kiện vào syslog hệ thống.
- **Các bước thực hiện:**
  1. Từ máy Host, gửi một gói tin tới cổng cấm: `nc -z -w 1 localhost 8888`
  2. Trên terminal QEMU, kiểm tra syslog: `tail -n 5 /var/log/messages`
- **Kết quả mong đợi:** Xuất hiện dòng log chứa tiền tố `[FW_DROP]` kèm thông tin chi tiết: `SRC=10.0.2.2 DST=10.0.2.15 PROTO=TCP SPT=... DPT=8888`.

### **Test Case 6.2: Hiển thị log chặn trên Web Dashboard**
- **Mục tiêu:** Đảm bảo các sự kiện chặn được CGI script parse thành JSON và hiển thị trực quan trên Web.
- **Các bước thực hiện:**
  1. Gửi gói tin cấm từ Host: `nc -z -w 1 localhost 8888`
  2. Mở Web Dashboard, chuyển sang tab **Security**.
- **Kết quả mong đợi:** Bảng **RECENT BLOCKED CONNECTIONS** xuất hiện dòng log mới ghi nhận sự kiện chặn cổng `8888` với IP nguồn `10.0.2.2` và Action là `DROP` (màu đỏ).

---

## 7. Custom Buildroot Package (miniguard-dashboard)
### **Test Case 7.1: Biên dịch tích hợp từ source cục bộ**
- **Mục tiêu:** Đảm bảo Buildroot nhận diện và đóng gói thành công package tự định nghĩa từ thư mục `src`.
- **Các bước thực hiện:**
  1. Trên máy Host (thư mục `buildroot`), chạy lệnh clean và rebuild package:
     ```bash
     make miniguard-dashboard-dirclean
     make miniguard-dashboard-rebuild
     ```
- **Kết quả mong đợi:** Quá trình biên dịch kết thúc thành công không lỗi. Kiểm tra thư mục đích `output/target/usr/share/miniguard/` trên Host thấy đầy đủ tệp tin giao diện `html/index.html` và cgi scripts mới nhất.

### **Test Case 7.2: Kiểm tra cấu hình Config.in của Package**
- **Mục tiêu:** Xác minh package hiển thị đúng trong menu cấu hình của Buildroot.
- **Các bước thực hiện:**
  1. Chạy lệnh: `make menuconfig`
  2. Di chuyển tới: `Target packages` -> `MiniGuard Embedded Security Gateway` (hoặc kiểm tra tìm kiếm `/miniguard-dashboard`).
- **Kết quả mong đợi:** Tùy chọn `miniguard-dashboard` xuất hiện đúng phân mục và có thể bật/tắt dễ dàng.

---

## 8. Tự khởi động cùng hệ thống (Auto-start Services)
### **Test Case 8.1: Kiểm tra trạng thái dịch vụ ngay sau khi boot**
- **Mục tiêu:** Đảm bảo khi hệ thống vừa khởi động xong, tường lửa và dashboard đã chạy ngầm sẵn sàng phục vụ.
- **Các bước thực hiện:**
  1. Khởi động QEMU, ngay khi dòng `miniguard login:` hiện lên (chưa cần đăng nhập).
  2. Trên máy Host, thử truy cập ngay Dashboard bằng trình duyệt: `http://localhost:8080/`
- **Kết quả mong đợi:** Trang dashboard tải thành công và hiển thị dữ liệu realtime ngay lập tức.

### **Test Case 8.2: Điều khiển dịch vụ thủ công qua Scripts khởi động**
- **Mục tiêu:** Xác minh các init script hỗ trợ đầy đủ các lệnh điều khiển dịch vụ tiêu chuẩn (`start`, `stop`, `restart`).
- **Các bước thực hiện:**
  1. Đăng nhập vào shell QEMU.
  2. Chạy lệnh tắt dashboard: `/etc/init.d/S50dashboard stop` rồi kiểm tra xem web còn vào được không.
  3. Chạy lệnh bật lại: `/etc/init.d/S50dashboard start` rồi kiểm tra lại web.
- **Kết quả mong đợi:** 
  - Sau lệnh `stop`, web báo lỗi không thể kết nối.
  - Sau lệnh `start`, web hoạt động bình thường trở lại.
