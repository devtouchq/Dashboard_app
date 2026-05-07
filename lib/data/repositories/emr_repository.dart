import '../../core/network/dio_client.dart';
import '../models/emr_data.dart';

class EmrRepository {
  final DioClient _client;

  EmrRepository(this._client);

  Future<EmrData> fetchEmr() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const EmrData(
      currentPatients: 581,
      totalPatients: 581,
      registration: 0,
      consultation: 0,
      bedsOccupied: 0,
      malePatients: 452,
      femalePatients: 129,
      ipPatients: 0,
      opPatients: 0,
      newPatients: 0,
      repeaterPatients: 0,
      patientFlow: [
        PatientFlowItem(label: 'Total', value: 581),
        PatientFlowItem(label: 'IP', value: 0),
        PatientFlowItem(label: 'OP', value: 0),
        PatientFlowItem(label: 'New', value: 0),
        PatientFlowItem(label: 'Repeat', value: 0),
      ],
    );
  }
}
