# Клас, що представляє пиріг
class Cake
  attr_reader :rows, :cols, :data, :raisins_coords

  def initialize(cake_str_array)
    # Перетворюємо масив рядків на масив масивів символів для легшого доступу
    @data = cake_str_array.map(&:chars)
    @rows = @data.size
    @cols = @data.first.size
    @raisins_coords = find_raisins
  end

  # Знаходить координати всіх родзинок у пирозі
  def find_raisins
    coords = []
    @data.each_with_index do |row, r_idx|
      row.each_with_index do |cell, c_idx|
        coords << [r_idx, c_idx] if cell == 'o'
      end
    end
    coords
  end

  # Підраховує кількість родзинок у заданому прямокутному регіоні
  # r1, c1 - верхня ліва координата
  # r2, c2 - нижня права координата
  def count_raisins_in_rect(r1, c1, r2, c2)
    count = 0
    (r1..r2).each do |r|
      (c1..c2).each do |c|
        # Перевіряємо, чи координати в межах пирога
        if r.between?(0, @rows - 1) && c.between?(0, @cols - 1)
          count += 1 if @data[r][c] == 'o'
        end
      end
    end
    count
  end

  # Отримує вміст шматка пирога у вигляді масиву рядків
  def get_piece_content(r1, c1, r2, c2)
    piece_content = []
    (r1..r2).each do |r|
      row_str = ""
      (c1..c2).each do |c|
        row_str << @data[r][c]
      end
      piece_content << row_str
    end
    piece_content
  end

  # Повертає загальну площу пирога
  def total_area
    @rows * @cols
  end
end

# Клас, що відповідає за розрізання пирога
class CakeSlicer
  def initialize(cake)
    @cake = cake
    @num_pieces = @cake.raisins_coords.size

    raise "Кількість родзинок має бути більше 1 та менше 10" unless @num_pieces > 1 && @num_pieces < 10
    raise "Площа пирога не ділиться на кількість шматків" if @cake.total_area % @num_pieces != 0

    @target_piece_area = @cake.total_area / @num_pieces
    @all_solutions = []
    # Стан, який відстежує, які клітинки вже зайняті шматками
    @used_cells = Array.new(@cake.rows) { Array.new(@cake.cols, false) }
  end

  # Основний метод для розрізання пирога
  def cut_cake
    find_cuts([]) # Починаємо рекурсивний пошук
    
    raise "Рішення не знайдено" if @all_solutions.empty?

    # Вибір рішення з максимальною шириною першого шматка
    best_solution = nil
    max_first_piece_width = -1

    @all_solutions.each do |solution|
      if solution.any?
        # Припускаємо, що перший шматок має рядок, і беремо його довжину
        first_piece_width = solution.first.first.size
        if first_piece_width > max_first_piece_width
          max_first_piece_width = first_piece_width
          best_solution = solution
        end
      end
    end
    best_solution
  end

  private

  # Рекурсивна функція для пошуку розрізів (бектрекінг)
  # current_pieces - список шматків, які вже знайшли для поточного шляху
  def find_cuts(current_pieces)
    # Базовий випадок: якщо ми знайшли потрібну кількість шматків
    if current_pieces.size == @num_pieces
      @all_solutions << current_pieces.dup # Додаємо копію рішення
      return
    end

    # Знаходимо першу незайняту клітинку, з якої почнемо будувати новий шматок
    start_r, start_c = find_first_free_cell
    return if start_r == -1 # Всі клітинки зайняті, але ми не знайшли достатньо шматків

    # Спроба створити прямокутник, починаючи з (start_r, start_c)
    # Перебираємо всі можливі нижні праві кути прямокутника (r2, c2)
    (start_r...@cake.rows).each do |r2|
      (start_c...@cake.cols).each do |c2|
        # Перевіряємо, чи всі клітинки в цьому потенційному прямокутнику вільні
        next unless is_rect_free?(start_r, start_c, r2, c2)

        current_piece_rows = r2 - start_r + 1
        current_piece_cols = c2 - start_c + 1
        current_piece_area = current_piece_rows * current_piece_cols

        next if current_piece_area != @target_piece_area # Площа має бути цільовою

        raisins_in_piece = @cake.count_raisins_in_rect(start_r, start_c, r2, c2)

        if raisins_in_piece == 1
          # Якщо прямокутник валідний, додаємо його до поточного рішення
          piece_content = @cake.get_piece_content(start_r, start_c, r2, c2)
          current_pieces << piece_content

          # Позначаємо клітинки цього шматка як зайняті
          mark_cells_as_used(start_r, start_c, r2, c2, true)

          # Рекурсивний виклик для пошуку наступних шматків
          find_cuts(current_pieces)

          # Відкат (бек трекінг): знімаємо позначки з клітинок і видаляємо шматок
          mark_cells_as_used(start_r, start_c, r2, c2, false)
          current_pieces.pop
        end
      end
    end
  end

  # Знаходить першу незайняту клітинку
  def find_first_free_cell
    (0...@cake.rows).each do |r|
      (0...@cake.cols).each do |c|
        return [r, c] unless @used_cells[r][c]
      end
    end
    [-1, -1] # Якщо всі клітинки зайняті
  end

  # Перевіряє, чи всі клітинки в заданому прямокутнику вільні
  def is_rect_free?(r1, c1, r2, c2)
    (r1..r2).each do |r|
      (c1..c2).each do |c|
        return false if @used_cells[r][c]
      end
    end
    true
  end

  # Позначає клітинки як зайняті або вільні
  def mark_cells_as_used(r1, c1, r2, c2, used)
    (r1..r2).each do |r|
      (c1..c2).each do |c|
        @used_cells[r][c] = used
      end
    end
  end
end


# --- Нова функція для відображення результату розрізання ---
# ... (весь код класів Cake та CakeSlicer залишається без змін) ...

# --- Нова функція для відображення результату розрізання (без ASCII-рамок) ---
def display_cut_cake_result(result_pieces, test_name)
  puts "Результат розрізання для #{test_name}:"
  
  result_pieces.each_with_index do |piece, i|
    # Виводимо вміст кожного шматка
    piece.each { |line| puts line }
    
    # Додаємо роздільник між шматками, як у вашому прикладі
    # Це може бути просто порожній рядок або коментар
    if i < result_pieces.size - 1
      puts "," # Роздільник, як у вашому прикладі
      puts ""  # Додатковий порожній рядок для кращого візуального розділення
    end
  end
  puts "\n" # Додатковий пустий рядок між тестами
end


# --- Приклад використання (модифікований вивід) ---
if __FILE__ == $0
  cake1_data = [
    "........",
    "..o.....",
    "...o....",
    "........"
  ]
  begin
    cake1 = Cake.new(cake1_data)
    slicer1 = CakeSlicer.new(cake1)
    result1 = slicer1.cut_cake
    display_cut_cake_result(result1, "Тест 1: Згідно з вашим прикладом")
  rescue StandardError => e
    puts "Помилка в Тесті 1: #{e.message}\n"
  end

  cake2_data = [
    ".o......",
    "......o.",
    "....o...",
    "..o....."
  ]
  begin
    cake2 = Cake.new(cake2_data)
    slicer2 = CakeSlicer.new(cake2)
    result2 = slicer2.cut_cake
    display_cut_cake_result(result2, "Тест 2: Приклад з кількома рішеннями")
  rescue StandardError => e
    puts "Помилка в Тесті 2: #{e.message}\n"
  end

  cake3_data = [
    ".o.o....",
    "........",
    "....o...",
    "........",
    ".....o..",
    "........"
  ]
  begin
    cake3 = Cake.new(cake3_data)
    slicer3 = CakeSlicer.new(cake3)
    result3 = slicer3.cut_cake
    display_cut_cake_result(result3, "Тест 3: Приклад з різними формами")
  rescue StandardError => e
    puts "Помилка в Тесті 3: #{e.message}\n"
  end

  cake4_data = [
    ".o",
    "o."
  ]
  begin
    cake4 = Cake.new(cake4_data)
    slicer4 = CakeSlicer.new(cake4)
    result4 = slicer4.cut_cake
    display_cut_cake_result(result4, "Тест 4: Простіший випадок")
  rescue StandardError => e
    puts "Помилка в Тесті 4: #{e.message}\n"
  end

  cake5_data = [
    "o...",
    ".o..",
    "..o.",
    "...o"
  ]
  begin
    cake5 = Cake.new(cake5_data)
    slicer5 = CakeSlicer.new(cake5)
    result5 = slicer5.cut_cake
    display_cut_cake_result(result5, "Тест 5: Якщо родзинки розташовані по діагоналі")
  rescue StandardError => e
    puts "Помилка в Тесті 5: #{e.message}\n"
  end
end