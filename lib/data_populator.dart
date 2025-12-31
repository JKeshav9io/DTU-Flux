import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

final Map<String, dynamic> weeklyTimetable = {
  "Monday": {
    "classes": [
      {
        "type": "lecture",
        "startTime": "09:00 AM",
        "endTime": "10:00 AM",
        "subjectName": "Database Management System",
        "subjectCode": "MC209",
        "faculty": "Ms. Trasha Gupta",
        "venue": "AB4-307",
      },
      {
        "type": "lecture",
        "startTime": "10:00 AM",
        "endTime": "12:00 PM",
        "subjectName": "Probability & Statistics",
        "subjectCode": "MC205",
        "faculty": "Dr. Devender Kumar",
        "venue": "AB3-307",
      },
      {
        "type": "lab",
        "startTime": "12:00 PM",
        "endTime": "02:00 PM",
        "subjectName": "Probability & Statistics",
        "subjectCode": "MC205",
        "groups": [
          {
            "group": "P4",
            "venue": "CL-1",
            "faculty": "Prof. R. Srivastava & Mr. Puneet K. Pal",
          },
          {
            "group": "P5",
            "venue": "CL-2",
            "faculty": "Dr. Meena Rawat & Ms. Aarti",
          },
          {
            "group": "P6",
            "venue": "CL-4",
            "faculty": "Mr. Jamkhongam Touthang & Ms. Priya Yadav",
          },
        ],
      },
      {
        "type": "lab",
        "startTime": "03:00 PM",
        "endTime": "05:00 PM",
        "subjectName": "Database Management System",
        "subjectCode": "MC209",
        "groups": [
          {
            "group": "P4",
            "venue": "CL-1",
            "faculty": "Ms. Himani Pokhriyal & Ms. Anjali Aggarwal",
          },
          {
            "group": "P5",
            "venue": "CL-2",
            "faculty": "Mr. Rohit Raghav & Mr. Aditya Parashar",
          },
          {
            "group": "P6",
            "venue": "CL-3",
            "faculty": "Mr. Kriss Gunjan & Ms. Neetu Malik",
          },
        ],
      },
    ],
  },

  "Tuesday": {
    "classes": [
      {
        "type": "lecture",
        "startTime": "10:00 AM",
        "endTime": "11:00 AM",
        "subjectName": "Real Analysis",
        "subjectCode": "MC203",
        "faculty": "Ms. Mahima",
        "venue": "AB3-307",
      },
      {
        "type": "lecture",
        "startTime": "11:00 AM",
        "endTime": "12:00 PM",
        "subjectName": "Real Analysis",
        "subjectCode": "MC203",
        "faculty": "Ms. Mahima",
        "venue": "AB3-308",
      },
      {
        "type": "lecture",
        "startTime": "02:00 PM",
        "endTime": "04:00 PM",
        "subjectName": "Database Management System",
        "subjectCode": "MC209",
        "faculty": "Ms. Trasha Gupta",
        "venue": "AB3-307",
      },
    ],
  },

  "Wednesday": {
    "classes": [
      {
        "type": "lecture",
        "startTime": "10:00 AM",
        "endTime": "11:00 AM",
        "subjectName": "Data Structure",
        "subjectCode": "MC201",
        "faculty": "Dr. Goonjab Jain",
        "venue": "AB3-307",
      },
      {
        "type": "lecture",
        "startTime": "11:00 AM",
        "endTime": "12:00 PM",
        "subjectName": "Probability & Statistics",
        "subjectCode": "MC205",
        "faculty": "Dr. Devender Kumar",
        "venue": "AB3-307",
      },
      {
        "type": "lecture",
        "startTime": "01:00 PM",
        "endTime": "03:00 PM",
        "subjectName": "Modern Algebra",
        "subjectCode": "MC207",
        "faculty": "Dr. Anshu",
        "venue": "AB3-307",
      },
    ],
  },

  "Thursday": {
    "classes": [
      {
        "type": "lecture",
        "startTime": "10:00 AM",
        "endTime": "11:00 AM",
        "subjectName": "Real Analysis",
        "subjectCode": "MC203",
        "faculty": "Ms. Mahima",
        "venue": "AB3-307",
      },
      {
        "type": "lecture",
        "startTime": "11:00 AM",
        "endTime": "12:00 PM",
        "subjectName": "Real Analysis",
        "subjectCode": "MC203",
        "faculty": "Ms. Mahima",
        "venue": "AB3-308",
      },
      {
        "type": "lab",
        "startTime": "12:00 PM",
        "endTime": "02:00 PM",
        "subjectName": "Data Structure",
        "subjectCode": "MC201",
        "groups": [
          {
            "group": "P4",
            "venue": "CL-1",
            "faculty": "Dr. Dinesh Udar & Ms. Shiksha Saini",
          },
          {
            "group": "P5",
            "venue": "CL-2",
            "faculty": "Prof. Sangita Kansal & Ms. Anju",
          },
          {
            "group": "P6",
            "venue": "CL-3",
            "faculty": "Ms. Trasha Gupta & Ms. Aarti",
          },
        ],
      },
    ],
  },

  "Friday": {
    "classes": [
      {
        "type": "lecture",
        "startTime": "08:00 AM",
        "endTime": "09:00 AM",
        "subjectName": "Data Structure",
        "subjectCode": "MC201",
        "faculty": "Dr. Goonjab Jain",
        "venue": "AB3-307",
      },
      {
        "type": "lecture",
        "startTime": "09:00 AM",
        "endTime": "10:00 AM",
        "subjectName": "Data Structure",
        "subjectCode": "MC201",
        "faculty": "Dr. Goonjab Jain",
        "venue": "AB3-308",
      },
      {
        "type": "lecture",
        "startTime": "11:00 AM",
        "endTime": "01:00 PM",
        "subjectName": "Modern Algebra",
        "subjectCode": "MC207",
        "faculty": "Dr. Anshu",
        "venue": "AB3-307",
      },
    ],
  },
};

Future<void> uploadTimetable() async {
  const String branch = "MCE";
  const String section = "B05";

  for (final entry in weeklyTimetable.entries) {
    final day = entry.key;
    final data = entry.value;

    await firestore
        .collection('branches')
        .doc(branch)
        .collection('sections')
        .doc(section)
        .collection('timetable')
        .doc(day)
        .set(data);

    debugPrint("Uploaded timetable for $day");
  }
}
