🎓 School Notes ENIAD — Student Grade Management System

A mobile academic management system built with Flutter and SQLite that simulates a real university platform for managing student grades, academic records, and semester reports.

📱 Project Overview

School Notes ENIAD is an academic project designed to digitalize the process of managing student grades.
The system allows teachers and students to interact with structured academic data such as modules, semesters, grades, and student profiles.

This project models a real higher-education structure with 5 academic years divided into two study cycles.

🏫 Academic Structure Modeled
🎓 Cycle Préparatoire (Years 1–2)

No specialization

Students organized by groups:
A1, A2, B1, B2, C1, C2

💻 Cycle Ingénieur (Years 3–5)

Specializations:

AI (Artificial Intelligence)

GINF

IRSI

ROC

Each specialization contains groups:

A

B

🚀 Main Features
👤 Student Side

Secure login system

View personal profile

View grades by module

View semester results

Export semester grade report (Relevé de notes) in CSV format

👨‍🏫 Academic Management

Student management (add / edit / delete)

Module management

Semester management

Grade entry (Contrôle, TP, Examen, Projet)

Automatic average calculation

Pass/Fail result calculation

📊 Statistics

Class average

Success rate

Best student

🧠 My Role — Database & Data Modeling

I was responsible for designing and implementing the data architecture of the system:

Conceptual Data Model (MCD) design

Database normalization

SQLite implementation

Flutter data models

CRUD operations

Relationships between:

Students

Modules

Notes

Semesters

Filières

🗄 Database Structure (Main Tables)

Student

Filiere

Module

Semestre

Prof

Note

The system supports:

5 academic levels

Multiple modules per semester

Large student groups

🛠 Tech Stack

Flutter

Dart

SQLite (sqflite)

MERISE Data Modeling

👥 Team

This project was developed in collaboration with:

Mahammed amzil

BELAIDI Souhaila

BETAHI Soukayna

Under the supervision of our professor at ENIAD.

🎯 Learning Outcomes

This project strengthened my skills in:

Database architecture

Academic system modeling

Data relationships & normalization

Mobile application data management

Building real-world structured systems

📌 Status

Academic project — Functional prototype
Future improvements may include:

Firebase synchronization

PDF export

Advanced analytics
