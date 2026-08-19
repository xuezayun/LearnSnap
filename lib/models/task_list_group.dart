import 'home_snapshot.dart';

enum TaskCategory {
  pending,
  rejected,
  awaitingReview,
  completed,
}

class TaskListSection {
  const TaskListSection({
    required this.category,
    required this.title,
    required this.items,
  });

  final TaskCategory category;
  final String title;
  final List<TodayBoxItem> items;
}

TaskCategory categoryForBox(TodayBoxItem box) {
  if (!box.submitted) return TaskCategory.pending;
  if (box.checkinStatus == 'rejected') return TaskCategory.rejected;
  if (box.canRevise) return TaskCategory.awaitingReview;
  return TaskCategory.completed;
}

String titleForCategory(TaskCategory category) {
  switch (category) {
    case TaskCategory.pending:
      return '还没拍';
    case TaskCategory.rejected:
      return '再拍一次会更好';
    case TaskCategory.awaitingReview:
      return '等家长看';
    case TaskCategory.completed:
      return '过关啦';
  }
}

List<TaskListSection> groupTasksByStatus(List<TodayBoxItem> boxes) {
  final order = [
    TaskCategory.pending,
    TaskCategory.awaitingReview,
    TaskCategory.rejected,
    TaskCategory.completed,
  ];
  final grouped = <TaskCategory, List<TodayBoxItem>>{};
  for (final box in boxes) {
    final category = categoryForBox(box);
    grouped.putIfAbsent(category, () => []).add(box);
  }
  return order
      .where((category) => grouped[category]?.isNotEmpty ?? false)
      .map(
        (category) => TaskListSection(
          category: category,
          title: titleForCategory(category),
          items: grouped[category]!,
        ),
      )
      .toList();
}
