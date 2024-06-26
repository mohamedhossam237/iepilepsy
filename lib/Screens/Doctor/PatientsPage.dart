import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class Patient {
  final String id;
  final String name;
  final int heartRate;
  final double eeg;
  final double ir1;
  final double ir2;

  Patient({
    required this.id,
    required this.name,
    required this.heartRate,
    required this.eeg,
    required this.ir1,
    required this.ir2,
  });

  factory Patient.fromFirestore(DocumentSnapshot doc, Map<String, dynamic> healthData) {
    return Patient(
      id: doc.id,
      name: doc['name'] ?? '',
      heartRate: healthData['heartRate'] ?? 0,
      eeg: healthData['eeg'] ?? 0.0,
      ir1: healthData['ir1'] ?? 0.0,
      ir2: healthData['ir2'] ?? 0.0,
    );
  }
}

class PatientsPage extends StatefulWidget {
  @override
  _PatientsPageState createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  Future<List<Patient>> _fetchDoctorPatients() async {
    String doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
    List<Patient> doctorPatients = [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('DoctorPatient')
        .doc(doctorId)
        .collection('patients')
        .get();

    for (var doc in querySnapshot.docs) {
      DocumentSnapshot healthSnapshot = await FirebaseFirestore.instance
          .collection('healthData')
          .doc(doc.id) // This assumes health data uses patient id as the document id
          .get();

      Map<String, dynamic> healthData =
      healthSnapshot.exists ? healthSnapshot.data() as Map<String, dynamic> : {};

      Patient patient = Patient.fromFirestore(doc, healthData);
      doctorPatients.add(patient);
    }

    return doctorPatients;
  }

  void _showAddPatientDialog() {
    TextEditingController idController = TextEditingController();
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      borderSide: BorderSide(color: Color(0xFFd1baf8), width: 2),
      width: MediaQuery.of(context).size.width * 0.9,
      buttonsBorderRadius: BorderRadius.all(Radius.circular(2)),
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: 'Add Patient',
      desc: 'Enter the patient ID to add:',
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: TextField(
              autofocus: true,
              controller: idController,
              decoration: InputDecoration(
                hintText: "Patient's ID",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Color(0xFFd1baf8), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
      btnOk: ElevatedButton(
        onPressed: () {
          // Functionality to add a patient
          _addPatient(idController.text);
        },
        style: ElevatedButton.styleFrom(primary: Color(0xFFd1baf8), onPrimary: Colors.white),
        child: Text('ADD'),
      ),
      btnCancelOnPress: () {},
    ).show();
  }

  Future<void> _addPatient(String patientId) async {
    String doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
    FirebaseFirestore.instance.collection('users').doc(patientId).get().then(
          (DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          Map<String, dynamic> patientData = documentSnapshot.data() as Map<String, dynamic>;
          patientData['doctorId'] = doctorId;
          FirebaseFirestore.instance.collection('DoctorPatient').doc(doctorId).collection('patients').doc(patientId).set(patientData).then(
                (_) {
              print("Patient added to DoctorPatient with doctorId");
              Navigator.of(context).pop();
            },
          ).catchError((error) => print("Failed to add patient: $error"));
        } else {
          print("Patient not found");
        }
      },
    ).catchError((error) => print("Failed to fetch patient: $error"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFd1baf8),
        title: Text("Patients Live Data", style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<Patient>>(
        future: _fetchDoctorPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else if (snapshot.hasData) {
            List<Patient> patients = snapshot.data!;
            return ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  color: Color(0xFFd1baf8).withOpacity(0.9),
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(patient.name, style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      "Heart Rate: ${patient.heartRate}, EEG: ${patient.eeg}, IR1: ${patient.ir1}, IR2: ${patient.ir2}",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            );
          } else {
            return Text("No patients found.");
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatientDialog,
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: Color(0xFFd1baf8)),
      ),
      backgroundColor: Color(0xFFd1baf8),
    );
  }
}
