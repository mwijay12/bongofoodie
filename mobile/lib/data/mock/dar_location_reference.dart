import '../models/models.dart';

/// Partial reviewed reference; IDs are internal, NOT official administrative codes.
/// Sources and scope: docs/polish-series/10-dar-location.md.
abstract final class DarLocationReference {
  static const regions = [TzRegion(code: 7, name: 'Dar es Salaam')];
  static const districts = [
    TzDistrict(code: 701, name: 'Kinondoni', regionCode: 7),
    TzDistrict(code: 702, name: 'Ilala', regionCode: 7),
    TzDistrict(code: 703, name: 'Temeke', regionCode: 7),
    TzDistrict(code: 704, name: 'Ubungo', regionCode: 7),
    TzDistrict(code: 705, name: 'Kigamboni', regionCode: 7),
  ];
  static const wards = [
    TzWard(code: 70101, name: 'Kijitonyama', districtCode: 701),
    TzWard(code: 70107, name: 'Kawe', districtCode: 701),
    TzWard(code: 70201, name: 'Kariakoo', districtCode: 702),
    TzWard(code: 70208, name: 'Tabata', districtCode: 702),
    TzWard(code: 70303, name: 'Kurasini', districtCode: 703),
    TzWard(code: 70304, name: 'Temeke', districtCode: 703),
    TzWard(code: 70401, name: 'Sinza', districtCode: 704),
    TzWard(code: 70402, name: 'Ubungo', districtCode: 704),
    TzWard(code: 70405, name: 'Kimara', districtCode: 704),
    TzWard(code: 70406, name: 'Mbezi', districtCode: 704),
    TzWard(code: 70407, name: 'Goba', districtCode: 704),
    TzWard(code: 70504, name: 'Mjimwema', districtCode: 705),
    TzWard(code: 70506, name: 'Somangila', districtCode: 705),
  ];
  // Common-place hint, deliberately separate from administrative ward names.
  static const placesByWard = {
    70506: ['Gezaulole']
  };
}
