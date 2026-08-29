// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DateEntryModelAdapter extends TypeAdapter<DateEntryModel> {
  @override
  final typeId = 4;

  @override
  DateEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DateEntryModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      date: fields[2] as DateTime,
      createdAt: fields[3] as DateTime,
      note: fields[4] == null ? '' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DateEntryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
