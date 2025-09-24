def cut_cake(cake)
  rows = cake.size
  cols = cake.first.size

  # знайдемо координати родзинок
  raisins = []
  cake.each_with_index do |row, i|
    row.chars.each_with_index do |cell, j|
      raisins << [i, j] if cell == 'o'
    end
  end

  n = raisins.size
  total_area = rows * cols
  raise "Площа не ділиться на #{n}" if total_area % n != 0

  target_area = total_area / n

  # спробуємо всі варіанти прямокутників
  possible_pieces = []

  # перебираємо всі можливі висоти h та ширини w прямокутника
  (1..rows).each do |h|
    next unless target_area % h == 0
    w = target_area / h
    next unless w <= cols

    # створюємо шматки за допомогою горизонтальних зрізів
    r = 0
    temp_pieces = []
    while r < rows
      row_slice = cake[r, h] || []
      piece = row_slice.map { |line| line[0, w] || "."*w }
      temp_pieces << piece
      r += h
    end

    # перевіряємо, чи у кожному шматку 1 родзинка
    if temp_pieces.all? { |p| p.join.count("o") == 1 } && temp_pieces.size == n
      possible_pieces << temp_pieces
    end
  end

  # вибираємо рішення з максимальною шириною першого шматка
  solution = possible_pieces.max_by { |pieces| pieces.first.first.size }
  raise "Рішення не знайдено" if solution.nil?

  solution
end

# --- приклад використання ---
if __FILE__ == $0
  cake1 = [
    "........",
    "..o.....",
    "...o....",
    "........"
  ]

  result = cut_cake(cake1)

  puts "Результат розрізання:"
  result.each_with_index do |piece, i|
    puts "Шматок #{i+1}:"
    piece.each { |line| puts line }
    puts "-"*20
  end
end
