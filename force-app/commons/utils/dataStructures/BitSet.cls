/**
* MIT License
*
* Copyright (c) 2020 Piotr Kożuchowski
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

/**
 * This class represents vector of bits (implemented by String of '0's and '1's)
 */
public with sharing class BitSet {
    private final static Map<String, String>
            HEX_BIN = new Map<String, String>{
                    '0' => '0000', '1' => '0001', '2' => '0010', '3' => '0011',
                    '4' => '0100', '5' => '0101', '6' => '0110', '7' => '0111',
                    '8' => '1000', '9' => '1001', 'a' => '1010', 'b' => '1011',
                    'c' => '1100', 'd' => '1101', 'e' => '1110', 'f' => '1111'
            },
            BASE64_CACHE = new Map<String, String>();
    private final static Integer ONE = '1'.charAt(0);


    private String bits = '';

    /**
     * @param base64 Base64 value of bytes ex. gAAA = 100000000000000000000000
     * @return BitSet constructed from decoded base64 value.
     */
    public static BitSet valueOfBase64(String base64) {
        String bits = BASE64_CACHE.get(base64);

        if (String.isBlank(bits)) {
            bits = '';
            Blob decoded = EncodingUtil.base64Decode(base64);
            String hex = EncodingUtil.convertToHex(decoded);

            for (Integer i = 0; i < hex.length(); i++) {
                bits += HEX_BIN.get(hex.substring(i, i + 1));
            }

            BASE64_CACHE.put(base64, bits);
        }

        return new BitSet(bits);
    }


    /**
     * Constructs bitset by given string which consists of '0's or '1's
     */
    public BitSet(String bits) {
        this.bits = bits;
    }


    /**
     * @return Bit at given index.
     */
    public Boolean get(Integer i) {
        return bits.charAt(i) == ONE;
    }

    /**
     * @return Size of BitSet.
     */
    public Integer size() {
        return bits.length();
    }

    public override String toString() {
        return bits;
    }
}