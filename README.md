# 📱 DTU-Flux

**DTU-Flux** is a smart academic and student activity management app designed for students and faculty of Delhi Technological University (DTU). It helps manage timetables, attendance, assignments, academic performance, notifications, and events—all in one app.

---

## 🌟 Key Highlights

- 📅 View personalized class timetables
- ✅ Mark and monitor attendance
- 📝 Upload and track assignments
- 📊 View academic results and SGPA/CGPA
- 📢 Receive push notifications for events, classes, and deadlines
- 🎉 Stay updated with campus events (currently posted by app developer)
- 🔒 Secure login and role-based access (Student, CR, Faculty)

> 🔹 *Note:* While faculty-specific features (like result updates and assignment upload) are built in, they are currently being used by CRs only.  
> 🔹 *Event publishing* is available in the system but currently used only by the app developer.  
> 🔹 *Offline support* using Hive is part of the system design but **not implemented yet**.

---

## 🖼️ App Screenshots

| Academic Performance | Assignmnets | Attendance |
|-------------|-----------|------------|
| ![Image](https://github.com/user-attachments/assets/b0eba6f6-14d6-49a7-bb86-ae046dd9ff45) | ![Image](https://github.com/user-attachments/assets/9870fd40-f247-4175-9e48-257989f40f2b) | ![Image](https://github.com/user-attachments/assets/2b720a61-7008-4437-a162-d6f7ebf19176) |

| Events | Home Screen | Manage Assignments |
|-------------|--------------------|------------------|
| ![Image](https://github.com/user-attachments/assets/df248061-3f81-44d0-9496-ce552e2c95bb) | ![Image](https://github.com/user-attachments/assets/ae084e0c-7cf0-40db-824a-09f0696a45fb) | ![Image](https://github.com/user-attachments/assets/efcd7ebe-a634-48f3-b25f-1ff923d5dc48) |

| Mark Attendance | Profile | Send Notification |
|----------------------|-------------------|--------|
| ![Image](https://github.com/user-attachments/assets/88b75996-5c2e-4baf-8359-212697bf1b9e) | ![Image](https://github.com/user-attachments/assets/451901ef-9a49-40a7-b13b-73cf8e80d931) | ![Image](https://github.com/user-attachments/assets/fe655fbe-773a-4e6f-a14e-292662655c5f) |

| Class Tine Table |
|---------|
| ![Image](https://github.com/user-attachments/assets/4961ab30-0318-4b65-b575-8cb62aa9b684) |

---

## 📌 Overview

DTU-Flux brings together various academic modules and integrates them into one unified mobile platform. Built with a **modular architecture**, it supports:

- Multi-role access for Students, CRs, and Faculty (though only Student + CR roles are actively used now)  
- Real-time data syncing using **Firebase**  
- Push notifications for important academic and event updates  
- Planned offline support and caching for smoother UX in the future

---

## ⚙️ Tech Stack

- **Frontend**: Flutter (cross-platform)
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **Notifications**: Firebase Cloud Messaging (FCM)
- *(Offline storage with Hive is part of the design but not implemented yet)*

---

## 🙌 Built For

- **Students** to view schedule, attendance, results, and event info  
- **CRs** to mark attendance, upload assignments, and send alerts  
- **Faculty** features are present in design, but not yet in active use  
- **Societies** can publish events (currently managed by app developer only)

---

> 💡 For detailed technical breakdown, refer to the [System Design Document](#) *(Upload and link it here if needed)*

---

Made with ❤️ by **Keshav Jha**  
📧 [keshav3453@gmail.com](mailto:keshav3453@gmail.com)
