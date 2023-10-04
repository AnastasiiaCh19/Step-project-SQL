# Завдання 1. Покажіть середню зарплату співробітників за кожен рік, до 2005 року.

-- Завдання можна виконати декількома способами, способи приведені за швидкістю виконання запиту від меншого до більшого)
# Спосіб 1 (запит з використанням агрегацийної функції та группування)

SELECT
    YEAR(from_date) AS salary_year, -- відокремлюємо рік з from_date
    AVG(salary) AS avg_salary -- агрегаційна функція що рахує середню зарплату
FROM salaries
WHERE YEAR(from_date) < 2005 -- фільтуємо данні до 2005 року
GROUP BY salary_year -- визначаемо группування по рокам
ORDER BY salary_year -- сортуємо по роках
;


# Спосіб 2 (використаємо СТЕ для обчислення середньої зарплати по роках)

WITH SalaryCTE AS ( -- створюємо CTE з назвою SalaryCTE, який обчислює середню зарплату за кожний рік до 2005 року
    SELECT
        YEAR(from_date) AS salary_year, -- відокремлюємо рік з from_date
        AVG(salary) AS avg_salary -- агрегаційна функція що рахує середню зарплату
    FROM salaries
    WHERE YEAR(from_date) < 2005 -- фільтуємо данні до 2005 року
    GROUP BY salary_year -- визначаемо группування по рокам
)

SELECT 
    salary_year,
    avg_salary
FROM SalaryCTE -- вибираємо дані з CTE
ORDER BY salary_year -- сортуємо по роках
;


# Спосіб 3 (використаємо віконну функцію для обчислення середньої зарплати по роках)

SELECT DISTINCT
    YEAR(from_date) AS salary_year, -- відокремлюємо рік з from_date
    AVG(salary) OVER (PARTITION BY YEAR(from_date)) AS avg_salary -- створення віконнї функції, щоб підрахувати середню зарплату для кожного року, розділяючи дані за роками за допомогою PARTITION BY YEAR(from_date)
FROM salaries
WHERE YEAR(from_date) < 2005 -- фільтуємо дані до 2005 року
ORDER BY salary_year -- сортуємо по роках
;


# Завдання 2. Покажіть середню зарплату співробітників по кожному відділу.
-- Примітка: потрібно розрахувати по поточній зарплаті, та поточному відділу співробітників

# Спосіб 1 (використаємо JOINs та агрегаційну функцію (швидкий за часом виконання запиту))

SELECT
    d.dept_name AS department,
    AVG(s.salary) AS avg_salary -- агрегаційна функція що рахує середню зарплату
FROM dept_emp AS de
JOIN departments AS d ON (de.dept_no = d.dept_no) -- об'єднуємо таблиці dept_emp, departments
JOIN salaries AS s ON (de.emp_no = s.emp_no) -- об'єднуємо з таблицею salaries
WHERE CURDATE() BETWEEN de.from_date AND de.to_date -- визначення поточних даних
GROUP BY department -- групуємо данні за департаментом
ORDER BY department -- визначаємо сотрування за департаментом
;


# Спосіб 2 (вікорістаємо СТЕ, віконну функцію та JOINs(є менш оптимальним за часом виконання запиту))

WITH AvgSalaries_cte AS ( -- створюємо CTE, а саме таблицю з назвами відділів, поточними зарплатами та середньою зарплатою кожного співробітника відділу
    SELECT
        d.dept_name AS department,
        s.salary,
        AVG(s.salary) OVER (PARTITION BY de.dept_no) AS avg_salary -- сворюємо віконну функцію для розрахунку середьої зарплати з группуванням за департаментом
    FROM dept_emp AS de
    JOIN departments AS d ON (de.dept_no = d.dept_no) -- об'єднуємо таблиці dept_emp, departments
    JOIN salaries AS s ON (de.emp_no = s.emp_no) -- об'єднуємо з таблицею salaries
    WHERE CURDATE() BETWEEN de.from_date AND de.to_date -- визначення поточних даних
)

SELECT DISTINCT department, avg_salary -- обираємо унікальні комбінації відділів та середніх зарплат, щоб показати середню зарплату для кожного відділу
FROM AvgSalaries_cte -- використовуємо створене СТЕ
ORDER BY department -- сортуємо за департаментом (але можна для сотрування обрати середню зарплату в залежності від умов задачі)
;


# Завдання 3. Покажіть середню зарплату співробітників по кожному відділу за кожний рік

# Спосіб 1
-- Спершу створюємо CTE з псевдонімом AvgSalaries
-- У цьому CTE ми обчислюємо середню зарплату для кожного відділу за кожний рік
WITH AvgSalaries AS (
    SELECT
        de.dept_no, 
        d.dept_name, 
        YEAR(s.from_date) AS salary_year, -- Витягуємо рік з дати from_date та називаємо його salary_year
        AVG(s.salary) AS avg_salary -- Обчислюємо середню зарплату для даного відділу та року
    FROM dept_emp AS de -- Об'єднуємо таблицю dept_emp з псевдонімом de (вказуємо, що з нею будемо працювати)
    JOIN departments AS d ON (de.dept_no = d.dept_no) -- Об'єднуємо результат з таблицею departments за полем dept_no
    JOIN salaries AS s ON (de.emp_no = s.emp_no) -- Об'єднуємо отриману таблицю з таблицею salaries за полем emp_no
    GROUP BY de.dept_no, d.dept_name, YEAR(s.from_date) -- Групуємо дані за номером відділу, назвою відділу та роком
)

-- Вибираємо дані з CTE AvgSalaries для виведення середньої зарплати співробітників по відділах за роками
SELECT dept_no, dept_name, salary_year, avg_salary
FROM AvgSalaries
ORDER BY dept_no, salary_year -- Сортуємо результати за номером відділу та роком.
;


# Спосіб 2
-- Вибираємо рік з поля from_date та обчислюємо середню зарплату співробітників по кожному відділу за кожний рік.
SELECT
	YEAR(s.from_date) AS year,
	d.dept_name,
	AVG(s.salary) AS avg_salary -- Обчислюємо середню зарплату співробітників та називаємо її avg_salary
FROM salaries AS s -- Використовуємо таблицю salaries та додаємо їй псевдонім
JOIN dept_emp de ON (s.emp_no = de.emp_no) -- Об'єднуємо таблиці salaries та dept_emp за полем emp_no
JOIN departments d ON (de.dept_no = d.dept_no) -- Об'єднуємо попередній результат з таблицею departments за полем dept_no
GROUP BY YEAR(s.from_date), d.dept_name -- Групуємо дані за роком та назвою відділу
ORDER BY YEAR(s.from_date), d.dept_name -- Сортуємо результати за роком та назвою відділу
;


# Спосіб 3 
-- Створюємо CTE AvgSalaries
-- У цьому CTE ми обчислюємо середню зарплату для кожного відділу за кожний рік
WITH AvgSalaries AS (
    SELECT
        de.dept_no, 
        d.dept_name, 
        YEAR(s.from_date) AS salary_year, -- Витягуємо рік з дати from_date та називаємо його salary_year
        s.salary,
        AVG(s.salary) OVER(PARTITION BY de.dept_no, YEAR(s.from_date)) AS avg_salary -- Обчислюємо середню зарплату за відділом та роком, використовуючи віконну функцію
    FROM dept_emp AS de -- Об'єднуємо таблицю dept_emp з псевдонімом de
    JOIN departments AS d ON (de.dept_no = d.dept_no) -- Об'єднуємо результат з таблицею departments за полем dept_no
    JOIN salaries AS s ON (de.emp_no = s.emp_no) -- Об'єднуємо отриману таблицю з таблицею salaries за полем emp_no
)

-- Вибираємо унікальні значення номеру відділу, назви відділу, року та середньої зарплати
SELECT DISTINCT dept_no, dept_name, salary_year, avg_salary
FROM AvgSalaries
ORDER BY dept_no, salary_year -- сортуємо результати за номером відділу та роком
;


# Завдання 4. Покажіть відділи в яких зараз працює більше 15000 співробітників.

# Спосіб 1
-- Створюємо CTE count_cte
-- У цьому CTE ми рахуємо кількість унікальних співробітників для кожного відділу
WITH count_cte AS (
	SELECT dept_no, COUNT(DISTINCT emp_no) AS count_empl -- Використовуємо агрегаційну функцію COUNT
	FROM dept_emp
	GROUP BY dept_no -- групуємо за номером департамента
)

SELECT d.dept_no, d.dept_name, c.count_empl
FROM count_cte AS c -- обираємо дані зі стореного СТЕ
JOIN departments d ON (c.dept_no = d.dept_no) -- об'єднуємо з таблицею departments для відображення назви департаменту
WHERE c.count_empl > 15000 -- фільтруємо відділи, де кількість співробітників більше 15000
;


# Спосіб 2
-- Створюємо CTE dept_employee_counts
-- У цьому CTE ми підраховуємо кількість співробітників для кожного відділу
WITH dept_employee_counts AS (
    SELECT
        d.dept_no, 
        d.dept_name, 
        COUNT(*) AS employee_count -- Підраховуємо кількість співробітників для даного відділу
    FROM departments AS d 
    JOIN dept_emp de ON (d.dept_no = de.dept_no) -- Об'єднуємо результат з таблицею dept_emp за полем dept_no
    GROUP BY d.dept_no, d.dept_name -- Групуємо результати за номером та назвою відділу
)

-- Вибираємо з CTE dept_employee_counts номер відділу, назву відділу та кількість співробітників
SELECT dept_no, dept_name, employee_count
FROM dept_employee_counts
WHERE employee_count > 15000 -- фільтруємо відділи, де кількість співробітників більше 15000
;


# Спосіб 3
-- Створюємо CTE dept_employee_counts
WITH dept_employee_counts AS (
	SELECT
		d.dept_no,
		d.dept_name,
		COUNT(*) OVER (PARTITION BY d.dept_no) AS employee_count -- за допомогою віконної функції обчислюємо кількість співробітників для кожного відділу
	FROM departments AS d
	JOIN dept_emp de ON (d.dept_no = de.dept_no) -- Об'єднуємо результат з таблицею dept_emp за полем dept_no
)

SELECT dept_no, dept_name, employee_count
FROM dept_employee_counts
WHERE employee_count > 15000 -- вибираємо тільки ті рядки, де кількість співробітників більше 15000
;


# Спосіб 4 (з вікорістання змінної)

SET @employee_threshold = 15000; -- Встановимо значення змінної для порівняння

-- Знайдемо відділи з більшою кількістю співробітників
SELECT  d.dept_no, 
		d.dept_name, 
        COUNT(*) AS employee_count -- підраховуємо кількість співробітників для відділу
FROM dept_emp AS de
JOIN departments AS d ON (de.dept_no = d.dept_no) -- об'єднуємо з таблицею департаментів для виведення назви департаменту
GROUP BY d.dept_no, d.dept_name -- групуємо за номером департамента та назвою
HAVING employee_count > @employee_threshold -- проводимо порівняння з змінною
;


# Завдання 5. Для менеджера який працює найдовше покажіть його номер, відділ, дату прийому на роботу, прізвище

# Спосіб 1
SELECT dm.emp_no, dm.dept_no, dp.dept_name, e.hire_date, e.last_name
FROM dept_manager AS dm
INNER JOIN employees AS e ON (dm.emp_no = e.emp_no) -- Об'єднуємо дані з даними з таблиці employees за номером співробітника
LEFT JOIN departments AS dp ON (dm.dept_no = dp.dept_no) -- Використовуємо LEFT JOIN, щоб об'єднати таблицю departments за номером відділу
ORDER BY DATEDIFF(dm.to_date, dm.from_date) DESC -- Сортуємо результати запиту за різницею між датами to_date і from_date у спадаючому порядку
LIMIT 1 -- візначаємо ліміт
;


# Спосіб 2 (за допомогою одного СТЕ)
-- для кожного менеджера розраховуємо тривалість його роботи в департаменті за допомогою СТЕ
WITH ManagerExperience AS (
    SELECT
        dm.emp_no AS manager_emp_no,
        dm.dept_no,
        DATEDIFF(MAX(dm.to_date), MIN(dm.from_date)) AS experience -- Розраховуємо різницю в днях між максимальною та мінімальною датами
    FROM dept_manager AS dm
    GROUP BY dm.emp_no, dm.dept_no
)

-- вибираємо менеджера з найдовшим досвідом та виводимо його номер, відділ, дату прийому на роботу та прізвище
SELECT
    me.manager_emp_no,
    me.dept_no,
    me.experience,
    e.last_name AS manager_last_name,
    d.dept_name
FROM ManagerExperience AS me
INNER JOIN employees AS e ON (me.manager_emp_no = e.emp_no) -- Об'єднуємо дані з даними з таблиці employees за номером співробітника
INNER JOIN departments AS d ON (me.dept_no = d.dept_no) -- об'єднуємо з таблицю departments за номером відділу
ORDER BY me.experience DESC -- соруємо за досвідом у спадаючому порядку
LIMIT 1 -- Вибираємо перший рядок, який буде мати найдовший досвід роботи менеджера
;


# Спосіб 3 (вирішення за допопмогою 2х CTE)
-- розраховуємо досвід менеджерів
WITH ManagerExperience AS (
    SELECT
        dm.emp_no AS manager_emp_no,
        dm.dept_no,
        DATEDIFF(dm.to_date, dm.from_date) AS experience
    FROM dept_manager AS dm 
),

-- визначаємо менеджера з найдовшим досвідом
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
)

-- Остаточний запит виводить інформацію про цього менеджера разом із відділом
SELECT
    lm.manager_emp_no,
    lm.dept_no,
    dp.dept_name,
    lm.hire_date,
    lm.last_name
FROM LongestManager AS lm
LEFT JOIN departments AS dp ON lm.dept_no = dp.dept_no
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


# Спосіб 2. Виведемо топ-10 діючих співробітників кожного відділу окремо з найбільшою різницею між їх зарплатою і середньою зарплатою в їх відділі.
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
FROM SecondManager AS nsm -- Данні беремо зі створеного СТЕ 2
JOIN departments d ON (sm.dept_no = d.dept_no) -- Приєднуємо таблицю департаментів щоб вивести назву депертаменту
;


# Дизайн бази даних:

/*  Завдання 1. Створіть базу даних для управління курсами. База має включати наступні таблиці: 
- students: student_no, teacher_no, course_no, student_name, email, birth_date.
- teachers: teacher_no, teacher_name, phone_no
- courses: course_no, course_name, start_date, end_date
*/

CREATE DATABASE IF NOT EXISTS courses_db; -- Щоб не було помилок


SHOW DATABASES; -- Список БД


USE courses_db;  -- візначаемо БД з якою будемо працювати

-- створюємо першу таблицю teachers
CREATE TABLE IF NOT EXISTS teachers (
	teacher_no char(5) NOT NULL PRIMARY KEY,
	teacher_name VARCHAR(30) NOT NULL,
	phone_no VARCHAR(30)
);


-- створюємо другу таблицю courses
CREATE TABLE IF NOT EXISTS courses (
	course_no char(6) NOT NULL PRIMARY KEY,
	course_name VARCHAR(30) NOT NULL,
	start_date DATE NOT NULL,
    end_date DATE NOT NULL
);


-- створюємо третю таблицю students
CREATE TABLE IF NOT EXISTS students (
	student_no INT AUTO_INCREMENT PRIMARY KEY,
	teacher_no char(5) NOT NULL,
	course_no char(6) NOT NULL,
	student_name VARCHAR(30) NOT NULL,
	email VARCHAR(30),
	birth_date DATE NOT NULL,
    FOREIGN KEY (teacher_no) REFERENCES teachers (teacher_no) -- Встановлюємо зовнішній ключ
					ON UPDATE RESTRICT ON DELETE CASCADE, 
    FOREIGN KEY (course_no) REFERENCES courses (course_no) -- Встановлюємо зовнішній ключ
					ON UPDATE RESTRICT ON DELETE CASCADE                
) AUTO_INCREMENT = 10001 -- вказуємо з якого номера почнуться записи
;
-- ON UPDATE RESTRICT обмежує зміну значення "teacher_no" у таблиці "teachers", якщо на нього є посилання у таблиці "students"
-- ON DELETE CASCADE встановлює автоматичне видалення записів з таблиці "students", якщо відповідний вчитель видаляється з таблиці "teachers"



DESCRIBE students; -- так можемо переглянути схему таблиці


# Завдання 2. Додайте будь-які данні (7-10 рядків) в кожну таблицю.
-- додаємо почергово дані в таблиці

INSERT INTO courses VALUES  
		('SQ-001', 'SQL', CURDATE(), '2023-12-01'), # Встановлюємо значення за допомогою функції CURDATE()
		('MT-001', 'Management', CURDATE(), '2024-02-01'),
        ('FC-001', 'Finance', CURDATE(), '2024-03-01'),
        ('PT-001','Pyton', '2023-10-15', '2024-01-10'),
        ('JV-001', 'Java', '2023-11-01', '2024-03-15'),
        ('FE-001', 'Frond_end', '2023-11-01', '2023-12-15'),
        ('DA-001', 'Data_analyst', CURDATE(), '2024-01-10'),
        ('PA-001', 'Product_analyst', '2023-12-01', '2024-02-01'),
        ('PM-001', 'Project_manager', CURDATE(), '2024-02-10'),
        ('RT-001', 'Recruiter', '2023-10-15', '2024-03-10')
;


INSERT INTO teachers VALUES  
	('t0001', 'Anna Golik', '+380976565789'),
    ('t0002', 'Alina Prutik', '+380509876899'),
    ('t0003', 'Oleg Reznichenko', '+380678930301'),
    ('t0004', 'Ivan Ponomarenko', '+380971123445'),
    ('t0005', 'Anastasiia Golova', '+380639085190'),
    ('t0006', 'Olena Derevnenko', '+380973434551'),
    ('t0007', 'Natalia Vesnenko', '+380506655147'),
    ('t0008', 'Anna Vozik', '+380739087655'),
    ('t0009', 'Oleksandr Grinko', '+380634545613'),
    ('t0010', 'Anastasiia Vesela', '+380508081833')
;

INSERT INTO students (teacher_no, course_no, student_name, email, birth_date) VALUES
	('t0001', 'SQ-001', 'Denic Sokirko', 'chytu@gmail.com', '1990-02-12' ),
    ('t0001', 'SQ-001', 'Anna Vitman', 'avit@gmail.com', '1999-03-02'),
    ('t0002', 'MT-001', 'Olga Soroka', 'olsor12@gmail.com', '1995-08-21'),
    ('t0003', 'FC-001', 'Sonia Kolik', 'soniakol@gmail.com', '1993-03-01'),
    ('t0003', 'FC-001', 'Tetanya Komar', 'komartet@gmail.com', '1992-04-16'),
    ('t0004', 'FC-001', 'Vladislav Lomov', 'lomov@gmail.com', '1991-07-07'),
    ('t0005', 'PT-001', 'Tetanya Kush', 'kush@gmail.com', '1990-08-17'),
    ('t0006', 'JV-001', 'Anna Moroz', 'moroz15@gmail.com', '1993-03-02'),
    ('t0008', 'FE-001', 'Vladimir Gorov', '768yt@gmail.com', '1998-06-06'),
    ('t0009', 'PM-001', 'Petr Novik', 'novik22@gmail.com', '1997-04-04')
;


SELECT * 
FROM students; 


# Завдання 3. По кожному викладачу покажіть кількість студентів з якими він працював

-- Спочатку ми створюємо СТЕ, який обчислює кількість студентів, з якими працював кожен викладач
WITH count_cte AS (
    SELECT teacher_no, COUNT(student_no) AS count_students -- Вибираємо викладачів та підраховуємо кількість студентів
    FROM students
    GROUP BY teacher_no -- Групуємо результати за викладачами
    ORDER BY teacher_no -- Сортуємо результати за номерами викладачів
)

-- Потім вибираємо дані з тимчасового CTE
SELECT
    t.teacher_no,
    t.teacher_name, 
    ct.count_students 
FROM count_cte AS ct -- Використовуємо дані з CTE count_cte
JOIN teachers AS t USING(teacher_no) -- З'єднуємо їх з таблицею teachers за номером викладача
;


# Завдання 4. Спеціально зробіть 3 дубляжі в таблиці students (додайте ще 3 однакові рядки)

INSERT INTO students (teacher_no, course_no, student_name, email, birth_date) VALUES
	('t0001', 'SQ-001', 'Denic Sokirko', 'chytu@gmail.com', '1990-02-12' ),
    ('t0001', 'SQ-001', 'Anna Vitman', 'avit@gmail.com', '1999-03-02'),
    ('t0002', 'MT-001', 'Olga Soroka', 'olsor12@gmail.com', '1995-08-21')
;


# Завдання 5. Напишіть запит який виведе дублюючі рядки в таблиці students.
-- групує рядки за іменем студента, адресою електронної пошти та датою народження і обчислює кількість дублюючих рядків для кожної 
-- унікальної комбінації цих полів. 
-- Рядки, які мають більше одного входження (тобто дублюються), виводяться.

# Cпосіб 1
SELECT teacher_no, course_no, student_name, email, birth_date, COUNT(*) -- рахуємо записи
FROM students
GROUP BY teacher_no, course_no, student_name, email, birth_date -- групуємо записи
HAVING COUNT(*) > 1  -- Вибираємо тільки групи, де кількість дубльованих записів більше одного
;


# Спосіб 2
-- Спершу створюємо CTE
-- В цьому CTE ми вибираємо всі дубльовані записи студентів, групуючи їх за іменем студента, електронною поштою та датою народження
-- HAVING COUNT(*) > 1 гарантує, що вибираються лише ті записи, які мають більше одного дублікату
WITH DuplicateStudents AS (
    SELECT student_name, email, birth_date
    FROM students
    GROUP BY student_name, email, birth_date
    HAVING COUNT(*) > 1
)

SELECT s.student_name, s.email, s.birth_date
FROM students AS s
JOIN DuplicateStudents AS ds ON (s.student_name = ds.student_name) -- використовуємо CTE для об'єднання дубльованих студентів зі всіма записами студентів у таблиці students
	AND (s.email = ds.email)
	AND (s.birth_date = ds.birth_date)
;
