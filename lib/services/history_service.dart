// import '../data/dao/service_history_dao.dart';
// import '../models/service_history.dart';
//
// class HistoryService {
//   final ServiceHistoryDao _dao;
//
//   HistoryService(this._dao);
//
//   Future<void> addHistory(ServiceHistoryItem history) async {
//     await _dao.insert(history);
//   }
//
//   Future<List<ServiceHistoryItem>> getUserHistory(String userId) async {
//     return await _dao.getByUserId(userId);
//   }
// }