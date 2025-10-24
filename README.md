# 🏫 Blockchain-based School Attendance System

A secure, transparent, and immutable attendance tracking system built on the Stacks blockchain using Clarity smart contracts.

## 🌟 Features

- **👩‍🏫 Teacher Management**: Register and manage teachers with role-based access
- **👨‍🎓 Student Enrollment**: Seamless student enrollment with class assignment
- **📋 Attendance Tracking**: Mark individual or bulk attendance with timestamps
- **📊 Real-time Statistics**: Automatic calculation of attendance rates and summaries
- **🔍 Transparent Records**: All attendance data stored immutably on blockchain
- **📈 Reporting**: Generate comprehensive attendance reports by class and date range
- **🔐 Access Control**: Role-based permissions for school administrators and teachers

## 🎯 How It Works

### Roles & Permissions

1. **School Owner/Administrator** 📋
   - Deploy and configure the contract
   - Register and deactivate teachers
   - Enroll and unenroll students
   - Set school name and semester information

2. **Teachers** 👩‍🏫
   - Mark attendance for students in their classes
   - Enroll new students (with permission)
   - Generate attendance reports
   - Use bulk attendance marking for efficiency

3. **Students** 👨‍🎓
   - Have their attendance tracked immutably
   - Benefit from transparent and tamper-proof records

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) for running tests
- A Stacks wallet for deployment

### Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd Blockchain-based-School-Attendance
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## 💻 Usage Examples

### 🏫 Setting Up Your School

```clarity
;; Set school name (Owner only)
(contract-call? .attendance-system set-school-name "Lincoln High School")

;; Set current semester
(contract-call? .attendance-system set-current-semester "Fall-2024")
```

### 👩‍🏫 Managing Teachers

```clarity
;; Register a new teacher
(contract-call? .attendance-system register-teacher 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  "Jane Smith" 
  "Mathematics")

;; Deactivate a teacher
(contract-call? .attendance-system deactivate-teacher 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### 👨‍🎓 Student Enrollment

```clarity
;; Enroll a student
(contract-call? .attendance-system enroll-student
  'SP3X6QWWETNQZURX0HR8E78Q8VG1YY5EKZ7MTHXY4
  "John Doe"
  "STU001"
  "10A")

;; Check if student is enrolled
(contract-call? .attendance-system is-student-enrolled
  'SP3X6QWWETNQZURX0HR8E78Q8VG1YY5EKZ7MTHXY4
  "10A")
```

### 📋 Marking Attendance

```clarity
;; Mark individual attendance
(contract-call? .attendance-system mark-attendance
  'SP3X6QWWETNQZURX0HR8E78Q8VG1YY5EKZ7MTHXY4
  "2024-09-20"
  "10A"
  "present"
  "On time")

;; Bulk attendance marking
(contract-call? .attendance-system bulk-mark-attendance
  (list 'SP3X6... 'SP4Y6... 'SP5Z7...)
  "2024-09-20"
  "10A"
  (list "present" "absent" "late"))
```

### 📊 Viewing Data

```clarity
;; Get student information
(contract-call? .attendance-system get-student-info
  'SP3X6QWWETNQZURX0HR8E78Q8VG1YY5EKZ7MTHXY4)

;; Get attendance record
(contract-call? .attendance-system get-attendance-record
  'SP3X6QWWETNQZURX0HR8E78Q8VG1YY5EKZ7MTHXY4
  "2024-09-20"
  "10A")

;; Get student statistics
(contract-call? .attendance-system get-student-stats
  'SP3X6QWWETNQZURX0HR8E78Q8VG1YY5EKZ7MTHXY4)
```

## 📊 Contract Functions

### Public Functions

| Function | Description | Access Level |
|----------|-------------|-------------|
| `set-school-name` | Update school name | Owner only |
| `set-current-semester` | Set academic semester | Owner only |
| `register-teacher` | Add new teacher | Owner only |
| `deactivate-teacher` | Remove teacher access | Owner only |
| `enroll-student` | Register new student | Owner/Teachers |
| `unenroll-student` | Remove student | Owner only |
| `mark-attendance` | Record attendance | Teachers only |
| `bulk-mark-attendance` | Record multiple attendance | Teachers only |
| `generate-attendance-report` | Create attendance report | Owner/Teachers |

### Read-Only Functions

| Function | Description |
|----------|-----------|
| `get-school-info` | Get school details |
| `get-teacher-info` | Get teacher information |
| `get-student-info` | Get student details |
| `get-attendance-record` | Get specific attendance record |
| `get-student-stats` | Get student attendance statistics |
| `get-daily-summary` | Get daily class attendance summary |
| `is-student-enrolled` | Check enrollment status |

## 🗂️ Data Structures

### Student Record
```clarity
{
  name: (string-ascii 50),
  student-id: (string-ascii 20),
  class: (string-ascii 20),
  enrolled-at: uint,
  active: bool
}
```

### Attendance Record
```clarity
{
  status: (string-ascii 10),    // "present", "absent", "late"
  marked-by: principal,
  marked-at: uint,
  notes: (string-ascii 100)
}
```

### Student Statistics
```clarity
{
  total-days: uint,
  present-days: uint,
  absent-days: uint,
  late-days: uint,
  attendance-rate: uint         // Percentage (0-100)
}
```

## ⚠️ Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `ERR_UNAUTHORIZED` | Caller lacks permission |
| u101 | `ERR_NOT_FOUND` | Record not found |
| u102 | `ERR_ALREADY_EXISTS` | Record already exists |
| u103 | `ERR_INVALID_DATE` | Invalid date format |
| u104 | `ERR_STUDENT_NOT_ENROLLED` | Student not enrolled |
| u105 | `ERR_ATTENDANCE_ALREADY_MARKED` | Attendance already recorded |
| u106 | `ERR_INVALID_STATUS` | Invalid attendance status |

## 🧪 Testing

Run the test suite to ensure contract functionality:

```bash
npm test
```

Tests cover:
- Contract deployment ✅
- Teacher registration and management ✅
- Student enrollment processes ✅
- Attendance marking workflows ✅
- Permission and access control ✅
- Statistical calculations ✅
- Error handling scenarios ✅

## 🚀 Deployment

### Local Development
```bash
clarinet console
```

### Testnet Deployment
```bash
clarinet deployments apply --deployment=testnet
```

### Mainnet Deployment
```bash
clarinet deployments apply --deployment=mainnet
```



## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Benefits of Blockchain-based Attendance

- **Immutability**: Records cannot be altered once written ✅
- **Transparency**: All stakeholders can verify attendance data 👁️
- **Decentralization**: No single point of failure 🌐
- **Cost-effective**: Reduces administrative overhead 💰
- **Real-time**: Instant access to attendance statistics ⚡
- **Auditable**: Complete audit trail for compliance 📋


