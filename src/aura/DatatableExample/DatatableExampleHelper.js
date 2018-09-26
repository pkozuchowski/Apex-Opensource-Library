({
    AccountGenerator: function (helper) {
        let index = 0;
        const nameGenerator = new NameGenerator();
        const ownerGenerator = new OwnerGenerator();
        const recordTypeGenerator = new RecordTypeGenerator();

        return {
            generate: function () {
                index++;
                return {
                    Id: "005" + ('' + index).padStart(12, "0"),
                    Name: nameGenerator.generate(),
                    Owner: ownerGenerator.generate(),
                    RecordType: recordTypeGenerator.generate()
                };
            }
        };

        function getRandomElement(list) {
            return list[Math.floor(Math.random() * list.length)];
        }

        function NameGenerator() {
            const prefixes = [
                "Acme", "Rocket", "Buldozer", "Candy", "Toys", "Muppets",
                "Gigle", "Pear", "Rosemary", "Ladybug", "Juicy", "Pocket", "Kitty",
                "Good", "Bad", "The Worst", "Notebook", "Laptop", "Gag"
            ];
            const sufixes = [
                "Company", "Brothers", "Inc.", "Customer", "Team"
            ];


            return {
                generate: function () {
                    return getRandomElement(prefixes)
                        + ' '
                        + getRandomElement(sufixes);
                }
            };
        }

        function OwnerGenerator() {
            const owners = [
                {Name: "John Travolta", Id: "005000000000000"},
                {Name: "Piotr K.", Id: "005000000000001"},
                {Name: "Bobby M.", Id: "005000000000001"},
                {Name: "M.M.", Id: "005000000000001"},
                {Name: "Mr. Pringles", Id: "005000000000001"}
            ];

            return {
                generate: function () {
                    return getRandomElement(owners);
                }
            };
        }

        function RecordTypeGenerator() {
            const owners = [
                {Name: "Account"},
                {Name: "Channel"},
                {Name: "Competitor"},
                {Name: "Agency"},
                {Name: "PersonAccount"}
            ];

            return {
                generate: function () {
                    return getRandomElement(owners);
                }
            };
        }
    },
})