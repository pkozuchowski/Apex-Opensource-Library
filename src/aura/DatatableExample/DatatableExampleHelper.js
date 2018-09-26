/**
 * MIT License
 *
 * Copyright (c) 2018 Piotr Kożuchowski
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
({
    AccountGenerator: function (helper) {
        let index = 0;
        const nameGenerator = new NameGenerator();
        const ownerGenerator = new OwnerGenerator();
        const recordTypeGenerator = new RecordTypeGenerator();

        return {
            generate: function () {
                index++;
                const rt = recordTypeGenerator.generate();
                const owner = ownerGenerator.generate();
                return {
                    Id: "005" + ('' + index).padStart(12, "0"),
                    Name: nameGenerator.generate(),
                    Owner: owner,
                    OwnerId: owner.Id,
                    RecordType: rt,
                    RecordTypeId: rt.Id
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
                {Id: "005000000000000", Name: "John Travolta"},
                {Id: "005000000000001", Name: "Piotr K."},
                {Id: "005000000000001", Name: "Bobby M."},
                {Id: "005000000000001", Name: "M.M."},
                {Id: "005000000000001", Name: "Mr. Pringles"}
            ];

            return {
                generate: function () {
                    return getRandomElement(owners);
                }
            };
        }

        function RecordTypeGenerator() {
            const owners = [
                {Id: "012000000000001", Name: "Account"},
                {Id: "012000000000002", Name: "Channel"},
                {Id: "012000000000003", Name: "Competitor"},
                {Id: "012000000000004", Name: "Agency"},
                {Id: "012000000000005", Name: "PersonAccount"}
            ];

            return {
                generate: function () {
                    return getRandomElement(owners);
                }
            };
        }
    },
})