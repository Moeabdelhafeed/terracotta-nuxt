// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_statement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletStatement _$WalletStatementFromJson(Map<String, dynamic> json) =>
    _WalletStatement(
      balance: json['balance'] as String?,
      transactions: json['transactions'] == null
          ? const <WalletTransaction>[]
          : _readTransactions(json['transactions']),
    );

Map<String, dynamic> _$WalletStatementToJson(_WalletStatement instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'transactions': instance.transactions,
    };
