# Завдання 1. Покажіть середню зарплату співробітників за кожен рік, до 2005 року.

SELECT
    YEAR(from_date) AS salary_year,
    AVG(salary) AS avg_salary
FROM salaries
WHERE YEAR(from_date) < 2005
GROUP BY salary_year
ORDER BY salary_year
;


# Завдання 2. Покажіть середню зарплату співробітників по кожному відділу.
-- Примітка: потрібно розрахувати по поточній зарплаті, та поточному відділу співробітників

# Спосіб 1
SELECT
    d.dept_name AS department,
    AVG(s.salary) AS avg_salary
FROM dept_emp AS de
JOIN departments AS d ON (de.dept_no = d.dept_no) -- об'єднуємо таблиці dept_emp, departments
JOIN salaries AS s ON (de.emp_no = s.emp_no) -- об'єднуємо з salaries для визначення поточного відділу та поточної зарплати кожного співробітника
WHERE CURDATE() BETWEEN de.from_date AND de.to_date
GROUP BY department
ORDER BY department
;-- обчислюємо середню зарплату для кожного відділу і виводимо результати


# Спосіб 2
WITH AvgSalaries_cte AS (
    SELECT
        d.dept_name AS department,
        s.salary,
        AVG(s.salary) OVER (PARTITION BY de.dept_no) AS avg_salary
    FROM dept_emp AS de
    JOIN departments AS d ON (de.dept_no = d.dept_no)
    JOIN salaries AS s ON (de.emp_no = s.emp_no)
    WHERE CURDATE() BETWEEN de.from_date AND de.to_date
) -- ми спершу створюємо спільну таблицю з назвами відділів, зарплатами та середньою зарплатою кожного співробітника відділу

SELECT DISTINCT department, avg_salary
FROM AvgSalaries_cte
ORDER BY department
; -- Потім ми вибираємо унікальні комбінації відділів та середніх зарплат, щоб показати середню зарплату для кожного відділу.


# Завдання 3. Покажіть середню зарплату співробітників по кожному відділу за кожний рік

# Спосіб 1

WITH AvgSalaries AS (
    SELECT
        de.dept_no,
        d.dept_name,
        YEAR(s.from_date) AS salary_year,
        AVG(s.salary) AS avg_salary
    FROM dept_emp AS de
    JOIN departments AS d ON (de.dept_no = d.dept_no)
    JOIN salaries AS s ON (de.emp_no = s.emp_no)
    GROUP BY de.dept_no, d.dept_name, YEAR(s.from_date)
) -- спершу створюємо спільну таблицю AvgSalaries, де обчислюємо середню зарплату (avg_salary) для кожного відділу (dept_no) за кожний рік (salary_year)

SELECT dept_no, dept_name, salary_year, avg_salary
FROM AvgSalaries
ORDER BY dept_no, salary_year
; -- вибираємо дані з цієї таблиці, щоб показати середню зарплату по відділах за роками


# Спосіб 2 
/* (У цьому запиті використуємо аналітичну функцію AVG() разом із віконною функцією OVER(PARTITION BY de.dept_no, YEAR(s.from_date)), 
 щоб обчислити середню зарплату для кожного відділа (dept_no) і року (salary_year) без використання підзапитів або групування даних.)*/
 
WITH AvgSalaries AS (
    SELECT
        de.dept_no,
        d.dept_name,
        YEAR(s.from_date) AS salary_year,
        s.salary,
        AVG(s.salary) OVER(PARTITION BY de.dept_no, YEAR(s.from_date)) AS avg_salary
    FROM dept_emp AS de
    JOIN departments AS d ON (de.dept_no = d.dept_no)
    JOIN salaries AS s ON (de.emp_no = s.emp_no)
)

SELECT DISTINCT dept_no, dept_name, salary_year, avg_salary
FROM AvgSalaries
ORDER BY dept_no, salary_year
;


# Спосіб 3
SELECT
  YEAR(s.from_date) AS year,
  d.dept_name,
  AVG(s.salary) AS avg_salary
FROM salaries AS s
JOIN dept_emp de ON (s.emp_no = de.emp_no) -- використаємо JOIN для об'єднання таблиць salaries, dept_emp і departments за потрібними полями
JOIN departments d ON (de.dept_no = d.dept_no)
GROUP BY YEAR(s.from_date), d.dept_name
ORDER BY YEAR(s.from_date), d.dept_name
;


# Завдання 4. Покажіть відділи в яких зараз працює більше 15000 співробітників.

# Спосіб 1

WITH count_cte AS (
  SELECT dept_no, COUNT(DISTINCT emp_no) AS count_empl
  FROM dept_emp
  GROUP BY dept_no
) -- обчислюємо кількість співробітників для кожного відділу у підзапиті

SELECT d.dept_no, d.dept_name, c.count_empl
FROM count_cte AS c
JOIN departments d ON (c.dept_no = d.dept_no) -- обчислюємо кількість співробітників для кожного відділу у підзапиті
WHERE c.count_empl > 15000; -- далі ми фільтруємо тільки ті відділи, де кількість співробітників більше 15000


# Спосіб 2
WITH dept_employee_counts AS (
  SELECT
    d.dept_no,
    d.dept_name,
    COUNT(*) AS employee_count
  FROM
    departments d
    JOIN dept_emp de ON d.dept_no = de.dept_no
  GROUP BY
    d.dept_no, d.dept_name
)
SELECT dept_no, dept_name, employee_count
FROM dept_employee_counts
WHERE employee_count > 15000
;


# Спосіб 3
WITH dept_employee_counts AS (
  SELECT
    d.dept_no,
    d.dept_name,
    COUNT(*) OVER (PARTITION BY d.dept_no) AS employee_count
  FROM
    departments d
    JOIN dept_emp de ON d.dept_no = de.dept_no
) -- за допомогою віконної функції COUNT(*) OVER обчислюємо кількість співробітників для кожного відділу
SELECT dept_no, dept_name, employee_count
FROM dept_employee_counts
WHERE employee_count > 15000
; -- Потім ми вибираємо тільки ті рядки, де кількість співробітників більше 15000.


# Спосіб 4 з вікорістання перемінної
-- Встановимо значення змінної для порівняння
SET @employee_threshold = 15000;

-- Знайдемо відділи з більшою кількістю співробітників
SELECT d.dept_no, d.dept_name, COUNT(*) AS employee_count
FROM dept_emp AS de
JOIN departments AS d ON de.dept_no = d.dept_no
GROUP BY d.dept_no, d.dept_name
HAVING employee_count > @employee_threshold;


# Завдання 5. Для менеджера який працює найдовше покажіть його номер, відділ, дату прийому на роботу, прізвище

# Спосіб 1
SELECT dm.emp_no, dm.dept_no, dp.dept_name, e.hire_date, e.last_name
FROM dept_manager AS dm
INNER JOIN employees AS e ON (dm.emp_no = e.emp_no)
LEFT JOIN departments AS dp ON (dm.dept_no = dp.dept_no)
ORDER BY DATEDIFF(dm.to_date, dm.from_date) DESC
LIMIT 1
;


# Спосіб 2
SELECT
    dm.emp_no AS manager_emp_no,
    dm.dept_no,
    DATEDIFF(MAX(dm.to_date), MIN(dm.from_date)) AS experience
FROM dept_manager AS dm
GROUP BY dm.emp_no, dm.dept_no
ORDER BY experience DESC
LIMIT 1;

# Спосіб 3 (за допомогою одного СТЕ)
WITH ManagerExperience AS (
    SELECT
        dm.emp_no AS manager_emp_no,
        dm.dept_no,
        DATEDIFF(MAX(dm.to_date), MIN(dm.from_date)) AS experience
    FROM dept_manager AS dm
    GROUP BY dm.emp_no, dm.dept_no
) -- для кожного менеджера розраховуємо тривалість його роботи в департаменті

SELECT
    me.manager_emp_no,
    me.dept_no,
    me.experience,
    e.last_name AS manager_last_name,
    d.dept_name
FROM ManagerExperience AS me
INNER JOIN employees AS e ON me.manager_emp_no = e.emp_no
INNER JOIN departments AS d ON me.dept_no = d.dept_no
ORDER BY me.experience DESC
LIMIT 1
; -- вибираємо менеджера з найдовшим досвідом та виводимо його номер, відділ, дату прийому на роботу та прізвище


# Спосіб 4 (вирішення за допопмогою 2х CTE)
WITH ManagerExperience AS (
    SELECT
        dm.emp_no AS manager_emp_no,
        dm.dept_no,
        DATEDIFF(dm.to_date, dm.from_date) AS experience
    FROM dept_manager AS dm 
), -- розраховуємо досвід менеджерів

LongestManager AS (
    SELECT
        me.manager_emp_no,
        me.dept_no,
        me.experience,
        e.hire_date,
        e.last_name
    FROM ManagerExperience AS me
    JOIN employees AS e ON me.manager_emp_no = e.emp_no
    ORDER BY me.experience DESC
    LIMIT 1
) -- визначаємо менеджера з найдовшим досвідом

SELECT
    lm.manager_emp_no,
    lm.dept_no,
    dp.dept_name,
    lm.hire_date,
    lm.last_name
FROM LongestManager AS lm
LEFT JOIN departments AS dp ON lm.dept_no = dp.dept_no -- Остаточний запит виводить інформацію про цього менеджера разом із відділом.
;


# Завдання 6. Покажіть топ-10 діючих співробітників компанії з найбільшою різницею між їх зарплатою і середньою зарплатою в їх відділі.

# Спосіб 1. Виведемо топ-10 діючих співробітників по всій компанії з найбільшою різницею між їх зарплатою і середньою зарплатою в їх відділі.
-- (Для вирішення викорістаємо два СТЕ, віконну функцію DENSE_RANK та Joins)

WITH Avg_dep_sal AS ( -- Створення СТЕ. Розрахунок середньої зарплати по кожному департаменту
  SELECT de.dept_no, AVG(salary) AS avg_dep_salary -- Використовуємо агрегацийну функцію для обчислення середньої зарплати
  FROM salaries AS s
  JOIN dept_emp de USING (emp_no)
  WHERE CURDATE() BETWEEN de.from_date AND de.to_date -- Фільтруємо обираючі тільки поточні ЗП для обрахунку
  GROUP BY de.dept_no -- Группування по номеру департамента
),
	Cur_sal AS ( -- Створення СТЕ для виведення поточної зарплати
SELECT emp_no, salary AS current_salary
FROM salaries
WHERE CURDATE() BETWEEN from_date AND to_date -- Фільтруємо обираючі тільки поточні ЗП
)

SELECT  e.emp_no, 
		CONCAT(e.first_name, ' ', e.last_name) AS Full_name, 
        cs.current_salary, 
        adv.avg_dep_salary,
		(cs.current_salary - adv.avg_dep_salary) AS diff_sal,
DENSE_RANK() OVER (ORDER BY (cs.current_salary - adv.avg_dep_salary) DESC )  'TOP_10 ' -- Створення віконної функції ранжування для віведення ТОП 10 працівників
FROM employees AS e
JOIN Cur_sal AS cs USING(emp_no) -- Приєднуємо наше СТЕ
JOIN dept_emp AS de ON (e.emp_no = de.emp_no) -- Приєднуємо таблицю департаментів
JOIN Avg_dep_sal AS adv ON (adv.dept_no = de.dept_no) -- Приєднуємо наше СТЕ
ORDER BY diff_sal DESC -- Сортуємо за спадінням
LIMIT 10 -- Вікорістовуємо LIMIT щоб залишити тільки 10 працивників у результуючій таблиці
;


# Спосіб 2. Виведемо топ-10 діючих співробітників кожного відділу з найбільшою різницею між їх зарплатою і середньою зарплатою в їх відділі.
-- (Для вирішення викорістаємо два СТЕ, віконну функцію RANK та Joins та підзапит)

-- Створимо запит для розрахунку середньої зарплати по відділах
WITH AvgSal_CTE AS (
    SELECT de.dept_no, AVG(s.salary) AS avg_department_salary
    FROM dept_emp de
    INNER JOIN salaries s ON de.emp_no = s.emp_no
    WHERE CURDATE() BETWEEN de.from_date AND de.to_date
    GROUP BY de.dept_no
),

-- Створимо запит для ранжування співробітників
RankedEmployees AS (
    SELECT
        de.dept_no,
        e.emp_no,
        e.first_name,
        e.last_name,
        cur_sal.salary,
        ABS(cur_sal.salary - AvgSal_CTE.avg_department_salary) AS salary_difference,
        RANK() OVER (PARTITION BY de.dept_no ORDER BY ABS(salary_difference) DESC) AS department_rank
    FROM employees e
    INNER JOIN dept_emp de ON e.emp_no = de.emp_no
    INNER JOIN AvgSal_CTE ON de.dept_no = AvgSal_CTE.dept_no
    INNER JOIN ( SELECT emp_no, salary
					FROM salaries
					WHERE CURDATE() BETWEEN from_date AND to_date) AS cur_sal ON (e.emp_no = cur_sal.emp_no)
) -- Використовуємо підзапит для обрахунку поточної зарплати співробітників

-- Основний запит для виведення топ-10 співробітників з найбільшою різницею зарплати в їхньому відділі по кожному із 9ти відлілів
SELECT
    dept_no,
    emp_no,
    first_name,
    last_name,
    salary,
    salary_difference,
    department_rank
FROM RankedEmployees
WHERE department_rank <= 10
ORDER BY dept_no, department_rank
;

    
# Завдання 7. Для кожного відділу покажіть другого по порядку менеджера. 
-- Необхідно вивести відділ, прізвище ім’я менеджера, дату прийому на роботу менеджера і дату коли він став менеджером відділу

# Спосіб 1 (використаємо СТЕ та віконну функцію, ранжування  проведемо за допомогою DENSE_RANK)

WITH dep_manager AS ( -- Створення СТЕ
  SELECT 
    dm.dept_no, 
    dp.dept_name AS name_of_department,
    CONCAT(e.first_name, ' ', e.last_name) AS manager_full_name, -- об'єднуємо ім'я та прізвище
    e.hire_date AS manager_hire_date,
    dm.from_date AS manager_start_date,
    DENSE_RANK() OVER (PARTITION BY dm.dept_no ORDER BY dm.from_date) AS manager_rank -- Створення віконної функції. Ранжуємо з групуванням по номеру департамента та сортуванням за датою прийняття на позицію менеджера
  FROM dept_manager AS dm
  JOIN employees AS e ON (dm.emp_no = e.emp_no) -- Приєднуємо таблицю працівників щоб вивести дату прийняття на роботу в компанію
  JOIN departments AS dp USING(dept_no) -- Приєднуємо таблицю департаментів щоб вивести назву депертаменту
)

SELECT -- Відбір даних що будуть в результуючій таблиці
  dm.dept_no,
  dm.name_of_department,
  dm.manager_full_name,
  dm.manager_hire_date,
  dm.manager_start_date,
  dm.manager_rank
FROM dep_manager AS dm -- Обираємо СТЕ де проводілісь розрахунки
WHERE dm.manager_rank = 2 -- Вибираємо другого по порядку менеджера
; 


# Спосіб 2 (використаємо два СТЕ, віконну функцію, ранжування проведемо за допомогою ROW_NUMBER)

WITH RankedManagers AS ( -- Створення СТЕ 1
  SELECT
    dm.dept_no,
    e.first_name AS manager_first_name,
    e.last_name AS manager_last_name,
    e.hire_date AS manager_hire_date,
    dm.from_date AS manager_start_date,
    ROW_NUMBER() OVER (PARTITION BY dm.dept_no ORDER BY dm.from_date) AS manager_rank -- Створення віконної функції. Ранжуємо з групуванням по номеру департамента та сортуванням за датою прийняття на позицію менеджера
  FROM dept_manager dm
  JOIN employees e ON dm.emp_no = e.emp_no -- -- Приєднуємо таблицю працівників щоб вивести ім'я, прізвище та дату прийняття на роботу в компанію
),

SecondManager AS ( -- Створення СТЕ 2
  SELECT
    rm.dept_no,
    rm.manager_first_name,
    rm.manager_last_name,
    rm.manager_hire_date,
    rm.manager_start_date
  FROM RankedManagers rm
  WHERE rm.manager_rank = 2 -- Вибираємо другого по порядку менеджера
)

SELECT -- Створення результуючої таблиці
  sm.dept_no,
  d.dept_name,
  CONCAT(sm.manager_first_name, ' ', sm.manager_last_name) AS manager_name,
  sm.manager_hire_date,
  sm.manager_start_date
FROM SecondManager sm -- Данні беремо зі створеного СТЕ 2
JOIN departments d ON sm.dept_no = d.dept_no -- Приєднуємо таблицю департаментів щоб вивести назву депертаменту
;


-- Дизайн бази даних:
/*  Завдання 1. Створіть базу даних для управління курсами. База має включати наступні таблиці: 
- students: student_no, teacher_no, course_no, student_name, email, birth_date.
- teachers: teacher_no, teacher_name, phone_no
- courses: course_no, course_name, start_date, end_date
*/

CREATE DATABASE IF NOT EXISTS courses_db; # Щоб не було помилок


SHOW DATABASES; # Список БД


USE courses_db;  # = set  as def schema


CREATE TABLE IF NOT EXISTS students (
	student_no INT AUTO_INCREMENT PRIMARY KEY,
	teacher_no INT NOT NULL,
	course_no INT NOT NULL,
	student_name VARCHAR(30) NOT NULL,
	email VARCHAR(30),
	birth_date DATE NOT NULL,
    FOREIGN KEY (teacher_no) REFERENCES teachers (teacher_no)
					ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (course_no) REFERENCES courses (course_no)
					ON UPDATE RESTRICT ON DELETE CASCADE                
);


DESCRIBE students;


SELECT * 
FROM students;


CREATE TABLE IF NOT EXISTS teachers (
	teacher_no INT AUTO_INCREMENT PRIMARY KEY,
	teacher_name VARCHAR(30) NOT NULL,
	phone_no VARCHAR(30)
);


CREATE TABLE IF NOT EXISTS courses2 (
	course_no INT AUTO_INCREMENT PRIMARY KEY,
	course_name VARCHAR(30) NOT NULL,
	start_date DATE DEFAULT CURDATE(),
    end_date DATE
);

DROP TABLE IF EXISTS courses;

# Завдання 2. Додайте будь-які данні (7-10 рядків) в кожну таблицю.

INSERT INTO courses (course_name, start_date, end_date)
VALUES  ('SQL', DEFAULT, '2023-12-01'), # Звертаемся до default значення
		('Management', DEFAULT, '2024-02-01'),
        ('Finance', DEFAULT, '2025-03-01'),
        ('Pyton', '2023-10-15', '2024-01-10'),
        ('Java', '2023-11-01', '2023-03-15'),
        ('Frond_end', '2023-11-01', '2023-12-15'),
        ('Data_analyst', DEFAULT, '2024-01-10'),
        ('Product_analyst', '2023-12-01', '2024-02-01'),
        ('Project_manager', DEFAULT, '2024-02-10'),
        ('Recruiter', '2023-10-15', '2024-03-10');
        
SELECT * 
FROM courses;