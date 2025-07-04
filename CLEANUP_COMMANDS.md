# FunPay Auto Boost - Complete Cleanup Commands

## 🧹 دستورات کامل پاک‌سازی

### 🚀 روش سریع - اجرای اسکریپت خودکار

```bash
# دانلود و اجرای اسکریپت پاک‌سازی
sudo bash cleanup_funpay.sh
```

### 🔧 روش دستی - دستورات جداگانه

#### 1. توقف و غیرفعال‌سازی سرویس
```bash
sudo systemctl stop funpay-boost
sudo systemctl disable funpay-boost
```

#### 2. حذف فایل‌های سرویس
```bash
sudo rm -f /etc/systemd/system/funpay-boost.service
sudo rm -rf /etc/systemd/system/funpay-boost.service.d/
sudo systemctl daemon-reload
```

#### 3. حذف اسکریپت مدیریت
```bash
sudo rm -f /usr/local/bin/funpay-boost
```

#### 4. کشتن پروسه‌های در حال اجرا
```bash
sudo pkill -f "funpay"
sudo pkill -f "firefox.*funpay"
sudo pkill -f "geckodriver"
sudo pkill -f "Xvfb.*99"
sudo pkill -f "Xvfb.*111"
```

#### 5. حذف دایرکتوری‌های نصب
```bash
sudo rm -rf /opt/funpay-boost
sudo rm -rf /etc/funpay
sudo rm -rf /var/log/funpay
```

#### 6. حذف کاربر سرویس
```bash
sudo rm -rf /home/funpay
sudo userdel funpay
```

#### 7. پاک‌سازی فایل‌های موقت
```bash
sudo rm -f /tmp/.X99-lock
sudo rm -f /tmp/.X111-lock
sudo rm -f /tmp/geckodriver*
sudo rm -f /tmp/funpay*
```

#### 8. پاک‌سازی نهایی پروسه‌ها
```bash
sudo pkill -9 -f firefox
sudo pkill -9 -f geckodriver
sudo pkill -9 -f Xvfb
```

### 🔍 بررسی پاک‌سازی

#### بررسی سرویس
```bash
systemctl list-unit-files | grep funpay
# نباید چیزی نمایش دهد
```

#### بررسی دایرکتوری‌ها
```bash
ls -la /opt/ | grep funpay
ls -la /etc/ | grep funpay
ls -la /var/log/ | grep funpay
# نباید چیزی نمایش دهد
```

#### بررسی کاربر
```bash
id funpay
# باید خطا دهد: id: 'funpay': no such user
```

#### بررسی پروسه‌ها
```bash
ps aux | grep funpay
pgrep -f funpay
# نباید چیزی نمایش دهد (به جز خود دستور grep)
```

### ⚡ دستور یکجا برای پاک‌سازی سریع

```bash
# دستور کامل یکجا (با احتیاط استفاده کنید)
sudo systemctl stop funpay-boost && \
sudo systemctl disable funpay-boost && \
sudo rm -f /etc/systemd/system/funpay-boost.service && \
sudo rm -rf /etc/systemd/system/funpay-boost.service.d/ && \
sudo systemctl daemon-reload && \
sudo rm -f /usr/local/bin/funpay-boost && \
sudo pkill -9 -f "funpay\|firefox.*funpay\|geckodriver\|Xvfb.*99\|Xvfb.*111" && \
sudo rm -rf /opt/funpay-boost /etc/funpay /var/log/funpay /home/funpay && \
sudo userdel funpay 2>/dev/null && \
sudo rm -f /tmp/.X99-lock /tmp/.X111-lock /tmp/geckodriver* /tmp/funpay* && \
echo "✅ FunPay Auto Boost completely removed!"
```

### 🛠️ عیب‌یابی مشکلات پاک‌سازی

#### اگر سرویس هنوز وجود دارد:
```bash
sudo systemctl reset-failed funpay-boost
sudo systemctl daemon-reload
sudo rm -f /etc/systemd/system/funpay-boost.service*
sudo systemctl daemon-reload
```

#### اگر پروسه‌ها هنوز در حال اجرا هستند:
```bash
# کشتن اجباری تمام پروسه‌های مرتبط
sudo killall -9 firefox geckodriver Xvfb
sudo fuser -k 99/tcp 2>/dev/null || true
```

#### اگر دایرکتوری‌ها قابل حذف نیستند:
```bash
# تغییر مالکیت و سپس حذف
sudo chown -R root:root /opt/funpay-boost /etc/funpay /var/log/funpay
sudo chmod -R 755 /opt/funpay-boost /etc/funpay /var/log/funpay
sudo rm -rf /opt/funpay-boost /etc/funpay /var/log/funpay
```

#### اگر کاربر قابل حذف نیست:
```bash
# کشتن تمام پروسه‌های کاربر و سپس حذف
sudo pkill -u funpay
sudo userdel -r funpay
```

### 📋 چک‌لیست نهایی

پس از اجرای دستورات پاک‌سازی، موارد زیر را بررسی کنید:

- [ ] سرویس systemd حذف شده
- [ ] دایرکتوری `/opt/funpay-boost` حذف شده
- [ ] دایرکتوری `/etc/funpay` حذف شده  
- [ ] دایرکتوری `/var/log/funpay` حذف شده
- [ ] کاربر `funpay` حذف شده
- [ ] اسکریپت `/usr/local/bin/funpay-boost` حذف شده
- [ ] هیچ پروسه مرتبطی در حال اجرا نیست
- [ ] فایل‌های موقت پاک شده‌اند

### ⚠️ نکات مهم

1. **همیشه با `sudo` اجرا کنید**
2. **قبل از پاک‌سازی، backup از تنظیمات بگیرید** (اگر نیاز دارید)
3. **دستورات را به ترتیب اجرا کنید**
4. **پس از هر مرحله، نتیجه را بررسی کنید**

### 🔄 نصب مجدد

اگر می‌خواهید سرویس را مجدداً نصب کنید:

```bash
# پس ا�� پاک‌سازی کامل
cd /path/to/FunPay_Auto_Boost_Offers
python3 funpay_boost_ultimate.py --setup
```