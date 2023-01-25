CREATE NODE TABLE Company (
    CompanyId INT64 NOT NULL
);

CREATE NODE TABLE University (
    UniversityId INT64 NOT NULL
);

CREATE NODE TABLE Continent (
    ContinentId INT64 NOT NULL
);

CREATE NODE TABLE Country (
    CountryId INT64 NOT NULL
);

CREATE NODE TABLE City (
    CityId INT64 NOT NULL
);
CREATE NODE TABLE Tag (
    TagId INT64 NOT NULL
);
CREATE NODE TABLE TagClass (
    TagClassId INT64 NOT NULL
);
CREATE NODE TABLE Forum (
    ForumId INT64 NOT NULL
);
CREATE NODE TABLE Comment (
    CommentId INT64 NOT NULL
);
CREATE NODE TABLE Post (
    PostId INT64 NOT NULL
);
CREATE NODE TABLE Person (
    PersonId INT64 NOT NULL
);

CREATE REL TABLE City_isPartOf_Country(FROM City TO Country);
CREATE REL TABLE Comment_hasCreator_Person(FROM Comment TO Person);
CREATE REL TABLE Comment_hasTag_Tag(From Comment TO Tag)
CREATE REL TABLE Comment_isLocatedIn_Country(FROM Comment TO Country);
CREATE REL TABLE Comment_replyOf_Comment(FROM Comment TO Comment);
CREATE REL TABLE Comment_replyOf_Post(FROM Comment TO Post);
CREATE REL TABLE Company_isLocatedIn_Country(FROM Company TO Country);
CREATE REL TABLE Country_isPartOf_Continent(FROM Country TO Continent);
CREATE REL TABLE Forum_containerOf_Post(FROM Forum TO Post);
CREATE REL TABLE Forum_hasMember_Person(FROM Forum TO Person);
CREATE REL TABLE Forum_hasModerator_Person(FROM Forum TO Person);
CREATE REL TABLE Forum_hasTag_Tag(FROM Forum TO Tag);
CREATE REL TABLE Person_hasInterest_Tag(FROM Person TO Tag);
CREATE REL TABLE Person_isLocatedIn_City(FROM Person TO City);
CREATE REL TABLE Person_knows_Person(FROM Person TO Person);
CREATE REL TABLE Person_likes_Comment(FROM Person TO Comment);
CREATE REL TABLE Person_likes_Post(FROM Person TO Post);
CREATE REL TABLE Person_studyAt_University(FROM Person TO University);
CREATE REL TABLE Person_workAt_Company(FROM Person TO Company);
CREATE REL TABLE Post_hasCreator_Person(FROM Post TO Person);
CREATE REL TABLE Post_hasTag_Tag(FROM Post TO Tag);
CREATE REL TABLE Post_isLocatedIn_Country(FROM Post TO Country);
CREATE REL TABLE TagClass_isSubclassOf_TagClass(FROM TagClass TO TagClass);
CREATE REL TABLE Tag_hasType_TagClass(FROM Tag TO TagClass);
CREATE REL TABLE University_isLocatedIn_City(FROM University TO City);