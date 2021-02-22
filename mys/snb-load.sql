LOAD DATA LOCAL INFILE 'PATHVAR/Company.csv'                   INTO TABLE Company                   FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/University.csv'                INTO TABLE University                FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Continent.csv'                 INTO TABLE Continent                 FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Country.csv'                   INTO TABLE Country                   FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/City.csv'                      INTO TABLE City                      FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Forum.csv'                     INTO TABLE Forum                     FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Comment.csv'                   INTO TABLE Comment                   FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Post.csv'                      INTO TABLE Post                      FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Person.csv'                    INTO TABLE Person                    FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Comment_hasTag_Tag.csv'        INTO TABLE Comment_hasTag_Tag        FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Post_hasTag_Tag.csv'           INTO TABLE Post_hasTag_Tag           FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Forum_hasMember_Person.csv'    INTO TABLE Forum_hasMember_Person    FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Forum_hasTag_Tag.csv'          INTO TABLE Forum_hasTag_Tag          FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Person_hasInterest_Tag.csv'    INTO TABLE Person_hasInterest_Tag    FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Person_likes_Comment.csv'      INTO TABLE Person_likes_Comment      FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Person_likes_Post.csv'         INTO TABLE Person_likes_Post         FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Person_studyAt_University.csv' INTO TABLE Person_studyAt_University FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Person_workAt_Company.csv'     INTO TABLE Person_workAt_Company     FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE 'PATHVAR/Person_knows_Person.csv' INTO TABLE Person_knows_Person FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS (person1id, person2id);
LOAD DATA LOCAL INFILE 'PATHVAR/Person_knows_Person.csv' INTO TABLE Person_knows_Person FIELDS TERMINATED BY '|' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS (person2id, person1id);
