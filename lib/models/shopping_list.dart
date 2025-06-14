import 'package:hive/hive.dart';
import 'shopping_item.dart';

part 'shopping_list.g.dart';

enum ShoppingListStatus {
  open,
  completed,
}

class ShoppingListStatusAdapter extends TypeAdapter<ShoppingListStatus> {
  @override
  final int typeId = 2;

  @override
  ShoppingListStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ShoppingListStatus.open;
      case 1:
        return ShoppingListStatus.completed;
      default:
        return ShoppingListStatus.open;
    }
  }

  @override
  void write(BinaryWriter writer, ShoppingListStatus obj) {
    switch (obj) {
      case ShoppingListStatus.open:
        writer.writeByte(0);
        break;
      case ShoppingListStatus.completed:
        writer.writeByte(1);
        break;
    }
  }
}

@HiveType(typeId: 0)
class ShoppingList extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime createdAt;

  @HiveField(2)
  ShoppingListStatus status;

  @HiveField(3)
  List<ShoppingItem> items;

  ShoppingList({
    required this.title,
    required this.createdAt,
    this.status = ShoppingListStatus.open,
    this.items = const [],
  });
}
