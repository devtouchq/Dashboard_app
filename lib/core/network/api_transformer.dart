import 'dart:convert';
import 'dart:io';

import '../utils/app_logger.dart';

/// Compresses/decompresses tqActions-style API requests and responses.
///
///  - Requests are converted to JSON, field names shortened via
///    `_writeMappings`, cleaned of null/empty defaults, gzipped, then
///    encoded as a Dictionary<int,int> JSON string (the format the
///    server expects).
///  - Responses arrive as gzipped bytes; after decompression the JSON
///    is normalized back to full field names via `_readMappings`.
///
/// This is shared across every endpoint that talks to the framework,
/// so keep the mapping tables in sync with the server.
class ApiTransformer {
  static const _tag = 'ApiTransformer';

  ApiTransformer() {
    _writeMappings.forEach((key, value) {
      _readMappings[value] = key;
    });
  }

  final Map<String, String> _readMappings = {
    r'"`Y"': r'"ID"',
    r'"`R"': r'"Value"',
    r'"`T"': r'"SelectedItem"',
    r'"`B"': r'"$type"',
    r'"`BW"': r'"Type"',
    r'"`DL"': r'"Data"',
    r'"`D7"': r'"Controls"',
    r'"`ZD"': r'"UniqueCompanyID"',
    r'"`ZE"': r'"AccId"',
    r'"`BJ"': r'"ModuleName"',
    r'"`BK"': r'"SubModuleName"',
    r'"`ZG"': r'"LoginType"',
    r'"`BL"': r'"AuthTocken"',
    r'"`DY"': r'"RequestID"',
    r'"`BI"': r'"UserAgent"',
    r'"`BD"': r'"ClientAppOS"',
    r'"`BE"': r'"ClientAppOSVersion"',
    r'"`BF"': r'"ClientAppType"',
    r'"`BG"': r'"ClientAppVersionNumber"',
    r'"`BH"': r'"Surface"',
    r'"`D1"': r'"controls"',
    r'"`BN"': r'"Columns"',
    r'"`BM"': r'"Rows"',
    r'"`BO"': r'"strName"',
    r'"`BP"': r'"strColHeader"',
    r'"`BQ"': r'"colType"',
    r'"`BR"': r'"iWidth"',
    r'"`BS"': r'"iMinWidth"',
    r'"`BU"': r'"strBGColor"',
    r'"`BX"': r'"NoOfPagesAvailable"',
    r'"`BY"': r'"CurrentPageIndex"',
    r'"`BZ"': r'"NoOfRowsPerPage"',
    r'"`B1"': r'"SpanInfoList"',
    r'"`B2"': r'"AdditionalHeaderRows"',
    r'"`DI"': r'"SelectedCells"',
    r'"`DD"': r'"CellValueIndex"',
    r'"`B3"': r'"CellMinimumValue"',
    r'"`B7"': r'"HeaderSpanInfoList"',
    r'"`DC"': r'"CachedRows"',
    r'"`B9"': r'"TotalRows"',
    r'"`B0"': r'"NormalTextColor"',
    r'"`DA"': r'"PositiveTextColor"',
    r'"`DB"': r'"NegativeTextColor"',
    r'"`DP"': r'"PositiveCellColor"',
    r'"`DH"': r'"FilterString"',
    r'"`DX"': r'"Name"',
  };

  final Map<String, String> _writeMappings = {
    r'"type":': r'"`A":',
    r':"COMBOBOX"': r':"`C"',
    r':"TEXTBOX"': r':"`D"',
    r':"TIMEPICKER"': r':"`E"',
    r':"BUTTON"': r':"`F"',
    r':"CHECkBOX"': r':"`G"',
    r':"DATEPICKER"': r':"`H"',
    r':"INTELI_FILE_MOVER"': r':"`I"',
    r':"HIDDEN"': r':"`J"',
    r':"LABEL"': r':"`K"',
    r':"RADIO"': r':"`L"',
    r'"m_strValue":': r'"`O":',
    r'"m_strText":': r'"`P":',
    r'"Text":': r'"`Q":',
    r'"Value":': r'"`R":',
    r'"SelectedIndex":': r'"`S":',
    r'"SelectedItem":': r'"`T":',
    r'"Selected":': r'"`U":',
    r'"Enabled":': r'"`V":',
    r'"Visible":': r'"`W":',
    r'"ListItems":': r'"`X":',
    r'"ID":': r'"`Y":',
    r'"$type":': r'"`B":',
    r'"Checked"': r'"`BA"',
    r'"HasSubItems"': r'"`BB"',
    r'"Marked"': r'"`BC"',
    r'"ClientAppOS"': r'"`BD"',
    r'"ClientAppOSVersion"': r'"`BE"',
    r'"ClientAppType"': r'"`BF"',
    r'"ClientAppVersionNumber"': r'"`BG"',
    r'"Surface"': r'"`BH"',
    r'"UserAgent"': r'"`BI"',
    r'"ModuleName"': r'"`BJ"',
    r'"SubModuleName"': r'"`BK"',
    r'"AuthTocken"': r'"`BL"',
    r'"Rows"': r'"`BM"',
    r'"Columns"': r'"`BN"',
    r'"strName"': r'"`BO"',
    r'"strColHeader"': r'"`BP"',
    r'"colType"': r'"`BQ"',
    r'"iWidth"': r'"`BR"',
    r'"iMinWidth"': r'"`BS"',
    r'"bReflectChangeAfterPostback"': r'"`BT"',
    r'"strBGColor"': r'"`BU"',
    r'"ColHeader"': r'"`BV"',
    r'"Type"': r'"`BW"',
    r'"NoOfPagesAvailable"': r'"`BX"',
    r'"CurrentPageIndex"': r'"`BY"',
    r'"NoOfRowsPerPage"': r'"`BZ"',
    r'"SpanInfoList"': r'"`B1"',
    r'"AdditionalHeaderRows"': r'"`B2"',
    r'"CellMinimumValue"': r'"`B3"',
    r'"ColorizeCell"': r'"`B4"',
    r'"ColorizeCellValue"': r'"`B5"',
    r'"CellColor"': r'"`B6"',
    r'"HeaderSpanInfoList"': r'"`B7"',
    r'"OfflineMode"': r'"`B8"',
    r'"TotalRows"': r'"`B9"',
    r'"NormalTextColor"': r'"`B0"',
    r'"PositiveTextColor"': r'"`DA"',
    r'"NegativeTextColor"': r'"`DB"',
    r'"CachedRows"': r'"`DC"',
    r'"CellValueIndex"': r'"`DD"',
    r'"ColorizeRow"': r'"`DE"',
    r'"NeedBackColor"': r'"`DF"',
    r'"DisablePaging"': r'"`DG"',
    r'"FilterString"': r'"`DH"',
    r'"SelectedCells"': r'"`DI"',
    r'"FocusToEnd"': r'"`DJ"',
    r'"Buffer"': r'"`DK"',
    r'"Data"': r'"`DL"',
    r'"Width"': r'"`DM"',
    r'"MinWidth"': r'"`DN"',
    r'"ReflectChangeAfterPostback"': r'"`DO"',
    r'"PositiveCellColor"': r'"`DP"',
    r'"CurrentCellInfo"': r'"`DQ"',
    r'"m_Id"': r'"`DR"',
    r'"m_iColIndex"': r'"`DS"',
    r'"m_cellType"': r'"`DT"',
    r'"CurrentSuggestionPageIndex"': r'"`DU"',
    r'"GridID"': r'"`DV"',
    r'"Name"': r'"`DX"',
    r'"RequestID"': r'"`DY"',
    r'"CurrentCellValue"': r'"`DZ"',
    r'"NegativeCellColor"': r'"`D0"',
    r'"controls"': r'"`D1"',
    r'"AddWithoutValidation"': r'"`D2"',
    r'"Suggestions"': r'"`D3"',
    r'"NumberOfSuggestionPagesAvailable"': r'"`D4"',
    r'"NoOfSuggestionsInPage"': r'"`D5"',
    r'"SufaceState"': r'"`D6"',
    r'"Controls"': r'"`D7"',
    r'"m_iColNameToFocus"': r'"`D8"',
    r'"RowData"': r'"`D9"',
    r'"m_cellData"': r'"`EA"',
    r'"tqActions.States.InteliTreeviewState,tqActions"': r'"`ZA"',
    r'"tqActions.States.InteliTextBoxState,tqActions"': r'"`ZB"',
    r'"tqActions.States.InteliGridState,tqActions"': r'"`ZC"',
    r'"UniqueCompanyID"': r'"`ZD"',
    r'"AccId"': r'"`ZE"',
    r'"tqActions.States.InteliButtonViewState,tqActions"': r'"`ZF"',
    r'"LoginType"': r'"`ZG"',
  };

  /// Compress `data` into the wire format the server expects: gzipped
  /// JSON, byte-by-byte, wrapped in a Dictionary<int,int>. Returns a
  /// JSON string ready to be POSTed as the request body.
  String compressRequest(Map<String, dynamic> data) {
    String jsonString = jsonEncode(data);

    // Shorten framework field names (harmless for endpoints that don't
    // use them — nothing will match and the string is unchanged).
    _writeMappings.forEach((key, value) {
      jsonString = jsonString.replaceAll(key, value);
    });

    jsonString = _cleanUpJson(jsonString);

    final compressedBytes = GZipCodec().encode(utf8.encode(jsonString));

    // Server expects a Dictionary<int,int>, not a raw byte array.
    final Map<String, int> dict = {
      for (int i = 0; i < compressedBytes.length; i++)
        i.toString(): compressedBytes[i],
    };

    return jsonEncode(dict);
  }

  /// Reverse the field-name shortening on a parsed response Map.
  /// Endpoints that don't use the framework's shortening will pass
  /// through unchanged.
  Map<String, dynamic> decompressResponse(Map<String, dynamic> responseData) {
    String jsonString = jsonEncode(responseData);

    _readMappings.forEach((key, value) {
      jsonString = jsonString.replaceAll(key, value);
    });

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Convenience: take raw response bytes, detect gzip via magic number,
  /// decompress, parse JSON, and apply readMappings in one call.
  Map<String, dynamic> handleCompressedResponse(List<int> responseBytes) {
    try {
      String jsonString;
      if (responseBytes.length >= 2 &&
          responseBytes[0] == 0x1f &&
          responseBytes[1] == 0x8b) {
        final decompressed = GZipCodec().decode(responseBytes);
        jsonString = utf8.decode(decompressed);
      } else {
        jsonString = utf8.decode(responseBytes);
      }

      final data = jsonDecode(jsonString);
      if (data is Map<String, dynamic>) {
        return decompressResponse(data);
      }
      return {};
    } catch (e) {
      AppLogger.error(_tag, 'handleCompressedResponse failed: $e');
      return {};
    }
  }

  /// Remove default/empty values the server doesn't need — reduces payload
  /// size and matches what the framework expects.
  String _cleanUpJson(String jsonString) {
    return jsonString
        .replaceAll('"ListItems":[],', '')
        .replaceAll('"ListItems":null,', '')
        .replaceAll('"SelectedItem":null,', '')
        .replaceAll('"Value":null,', '')
        .replaceAll('"Text":null,', '')
        .replaceAll('"Tag":null,', '')
        .replaceAll('"WaterMarkText":null,', '')
        .replaceAll('"BorderColor":null,', '')
        .replaceAll('"BackColor":null,', '')
        .replaceAll('"StyleVal":null,', '')
        .replaceAll('"Value":"",', '')
        .replaceAll('"Text":"",', '')
        .replaceAll('"Tag":"",', '')
        .replaceAll('"WaterMarkText":"",', '')
        .replaceAll('"BorderColor":"",', '')
        .replaceAll('"BackColor":"",', '')
        .replaceAll('"StyleVal":"",', '')
        .replaceAll('"SelectedIndex":-1,', '')
        .replaceAll('"HasFocus":false,', '')
        .replaceAll('"Checked":false,', '')
        .replaceAll('"Border":false,', '')
        .replaceAll('"Enabled":true,', '')
        .replaceAll('"Visible":true,', '')
        .replaceAll('"Visibility":0,', '')
        .replaceAll(',,', ',')
        .replaceAll(',}', '}');
  }
}
