// Midnight(local hour) of the given day
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

// Add calendary days
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
