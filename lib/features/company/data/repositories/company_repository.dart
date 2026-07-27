import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/company.dart';
import '../../domain/repositories/company_repository_interface.dart';

class CompanyRepository implements ICompanyRepository {
  final ApiClient _apiClient;

  CompanyRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Company> createCompany(Company company) async {
    try {
      debugPrint("COMPANY OBJECT:");
      debugPrint(company.toString());

      debugPrint("COMPANY JSON:");
      debugPrint(jsonEncode(company.toJson()));

      final response = await _apiClient.post('/company', data: company.toJson());
      final map = _extractMap(response);
      return Company.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<Company>> getCompanies() async {
    try {
      final response = await _apiClient.get('/company');
      final list = _extractList(response);
      return list
          .map((item) => Company.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Company> getCompanyById(String id) async {
    try {
      final response = await _apiClient.get('/company/$id');
      final map = _extractMap(response);
      return Company.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Company> getCompanyByName(String name) async {
    try {
      final encodedName = Uri.encodeComponent(name);
      final response = await _apiClient.get('/company/name/$encodedName');
      final map = _extractMap(response);
      return Company.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Company> updateCompany(String id, Company company) async {
    try {
      final response = await _apiClient.put('/company/$id', data: company.toJson());
      final map = _extractMap(response);
      return Company.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> deleteCompany(String id) async {
    try {
      await _apiClient.delete('/company/$id');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw UnknownException('Unexpected response format: Expected JSON Map');
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is Map<String, dynamic> && response.containsKey('data') && response['data'] is List) {
      return response['data'] as List;
    }
    throw UnknownException('Unexpected response format: Expected JSON List');
  }
}
