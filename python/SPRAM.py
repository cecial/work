#!/usr/bin/env python3

class SPRAM:
    """
    Usage:
        SPRAM(words,bits,cycle_time)
            create a new memory, with words x bits density, 
            cycle_time's  unit is ns, default value is 10
            you can use dict to specify following info of memory:
                "clkname",
                "adrname",
                "diname",
                "doname",
                "cename","ce_when_read","ce_when_write","ce_when_standby",
                "wename","we_when_read","we_when_write","we_when_standby",

        write(word,di)
            write di to memory word, di is like "01010101" for a 8 bits memory
            default do is x when write, you can add do state by write(word, di, do="01...")

        read(word)
            read from memory word, 
            default di is '0' x bits. you can you can add di state by read(word,di="01...")

        standby()
            put memory in standby mode, default word=0, di=0, do=x
            you can add state by standby(word=new_word, di="01...", do="01...")

        comment("comments")
            add comments in vec file, mostly add comment before operation

        write_vec(filename)
            write vec in filename, default filename is spram_func.vec


    example:
    import spram_func

    x=spram_func.SPRAM(words=1024, bits=8,cycle_time=20, clkname = "CK")
    x.comment("now write")
    x.write(0,"01100110")
    x.comment("now read")
    x.read(0)
    x.write_vec("test.vec")

    """

    def __init__(self, words=8, bits=2, cycle_time=10, **arg):

        # initial memory data, all memory bits store 'x'
        self.words = words
        self.bits = bits
        self.data = [[ 'x' for b in range(bits)] for w in range(words)]
        self.adr_width = len(format(words-1,'b'))

        self.cycle_time = cycle_time

        ################################################################################
        # initial pin names and pin active state for read/write/standby
        self.clkname = "CLK"
        self.adrname = "A"
        self.diname  = "D"
        self.doname  = "Q"

        self.cename        = "CEN"
        self.ce_when_read  = "0"
        self.ce_when_write = "0"
        self.ce_when_standby  = "1"

        self.wename        = "WEN"
        self.we_when_read  = "1"
        self.we_when_write = "0"
        self.we_when_standby  = "0"

        legal_attr = [
                "clkname",
                "adrname",
                "diname",
                "doname",
                "cename","ce_when_read","ce_when_write","ce_when_standby",
                "wename","we_when_read","we_when_write","we_when_standby",
                ]

        # set attribution for memory
        for k,v in arg.items():
            if k in legal_attr :
                setattr(self,k,str(v))
            else :
                print(k," is illegal attribution for ",self)

        ################################################################################

        #initial parameters for vec file output
        self.cycle_number = 0
        self.vectors      = [] 

    ################################################################################
    ### write operation
    ################################################################################
    def write (self,word,di,**arg) :  # write(word,di,do="xxx",increase_cycle=0
        do = "x" * self.bits # default do for write
        if ('do' in arg) :
            do = arg['do']

        if (word >= self.words) :
            print("word {} is out of memory words range: {}".format(word, self.words))

        if (len(di) > self.bits) :
            print("di={}, len = {} is out of memory bits range: {}".format(di, len(di), self.bits))

        if (len(do) > self.bits) :
            print("do={}, len = {} is out of memory bits range: {}".format(do, len(do), self.bits))

        # write data=di into memory
        for i in range(self.bits) :
            self.data[word][i]=str(di[i])


        # prepare for vec out
        if (len(self.vectors)==self.cycle_number) :
            self.vectors.append([])

        if (len(self.vectors[self.cycle_number])==0) :
            # no operation yet, no comment yet
            self.vectors[self.cycle_number]=[{},{},{},{}]

        self.vectors[self.cycle_number][0]["clk"] = "0";
        self.vectors[self.cycle_number][0]["ce"]  = self.ce_when_write
        self.vectors[self.cycle_number][0]["we"]  = self.we_when_write
        self.vectors[self.cycle_number][0]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][0]["di"]  = di
        self.vectors[self.cycle_number][0]["do"]  = "x" * self.bits

        self.vectors[self.cycle_number][1]["clk"] = "1";
        self.vectors[self.cycle_number][1]["ce"]  = self.ce_when_write
        self.vectors[self.cycle_number][1]["we"]  = self.we_when_write
        self.vectors[self.cycle_number][1]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][1]["di"]  = di
        self.vectors[self.cycle_number][1]["do"]  = do

        self.vectors[self.cycle_number][2]["clk"] = "1";
        self.vectors[self.cycle_number][2]["ce"]  = self.ce_when_write
        self.vectors[self.cycle_number][2]["we"]  = self.we_when_write
        self.vectors[self.cycle_number][2]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][2]["di"]  = di
        self.vectors[self.cycle_number][2]["do"]  = "x" * self.bits

        self.vectors[self.cycle_number][3]["clk"] = "0";
        self.vectors[self.cycle_number][3]["ce"]  = self.ce_when_write
        self.vectors[self.cycle_number][3]["we"]  = self.we_when_write
        self.vectors[self.cycle_number][3]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][3]["di"]  = di
        self.vectors[self.cycle_number][3]["do"]  = "x" * self.bits

        # increase the cycle_number
        if (("increase_cycle" in arg) and (arg['increase_cycle'] == 0)) :
            pass
        else :
            self.cycle_number += 1

    ################################################################################
    ### read operation
    ################################################################################
    def read (self,word,**arg) :  # read (word,di="xxx",increase_cycle=0
        di = "0" * self.bits # default di for read
        if ('di' in arg) :
            di = arg['di']

        if (word >= self.words) :
            print("word {} is out of memory words range: {}".format(word, self.words))

        if (len(di) > self.bits) :
            print("di={}, len = {} is out of memory bits range: {}".format(di, len(di), self.bits))

        # read data from memory
        do = ""
        for i in range(self.bits) :
            do += str(self.data[word][i])

        # prepare for vec out
        if (len(self.vectors)==self.cycle_number) :
            self.vectors.append([])

        if (len(self.vectors[self.cycle_number])==0) :
            # no operation yet, no comment yet
            self.vectors[self.cycle_number]=[{},{},{},{}]
        
        self.vectors[self.cycle_number][0]["clk"] = "0";
        self.vectors[self.cycle_number][0]["ce"]  = self.ce_when_read
        self.vectors[self.cycle_number][0]["we"]  = self.we_when_read
        self.vectors[self.cycle_number][0]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][0]["di"]  = di
        self.vectors[self.cycle_number][0]["do"]  = "x" * self.bits

        self.vectors[self.cycle_number][1]["clk"] = "1";
        self.vectors[self.cycle_number][1]["ce"]  = self.ce_when_read
        self.vectors[self.cycle_number][1]["we"]  = self.we_when_read
        self.vectors[self.cycle_number][1]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][1]["di"]  = di
        self.vectors[self.cycle_number][1]["do"]  = do

        self.vectors[self.cycle_number][2]["clk"] = "1";
        self.vectors[self.cycle_number][2]["ce"]  = self.ce_when_read
        self.vectors[self.cycle_number][2]["we"]  = self.we_when_read
        self.vectors[self.cycle_number][2]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][2]["di"]  = di
        self.vectors[self.cycle_number][2]["do"]  = "x" * self.bits

        self.vectors[self.cycle_number][3]["clk"] = "0";
        self.vectors[self.cycle_number][3]["ce"]  = self.ce_when_read
        self.vectors[self.cycle_number][3]["we"]  = self.we_when_read
        self.vectors[self.cycle_number][3]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][3]["di"]  = di
        self.vectors[self.cycle_number][3]["do"]  = "x" * self.bits

        # increase the cycle_number
        if (("increase_cycle") in arg and (arg['increase_cycle'] == 0)) :
            pass
        else :
            self.cycle_number += 1

    ################################################################################
    ### standby operation
    ################################################################################
    def standby (self,**arg) :  # read (word="xxx", di="xxx", do="xxx", increase_cycle=0
        word = 0 # default word for standby
        if ('word' in arg) :
            word = arg['word']

        di = "0" * self.bits # default di for standby
        if ('di' in arg) :
            di = arg['di']

        do = "x" * self.bits # default do for standby
        if ('do' in arg) :
            do = arg['do']

        if (word >= self.words) :
            print("word {} is out of memory words range: {}".format(word, self.words))

        if (len(di) > self.bits) :
            print("di={}, len = {} is out of memory bits range: {}".format(di, len(di), self.bits))

        if (len(do) > self.bits) :
            print("do={}, len = {} is out of memory bits range: {}".format(do, len(do), self.bits))

        # prepare for vec out
        if (len(self.vectors)==self.cycle_number) :
            self.vectors.append([])

        if (len(self.vectors[self.cycle_number])==0) :
            # no operation yet, no comment yet
            self.vectors[self.cycle_number]=[{},{},{},{}]
        
        self.vectors[self.cycle_number][0]["clk"] = "0";
        self.vectors[self.cycle_number][0]["ce"]  = self.ce_when_standby
        self.vectors[self.cycle_number][0]["we"]  = self.we_when_standby
        self.vectors[self.cycle_number][0]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][0]["di"]  = di
        self.vectors[self.cycle_number][0]["do"]  = "x" * self.bits

        self.vectors[self.cycle_number][1]["clk"] = "0";
        self.vectors[self.cycle_number][1]["ce"]  = self.ce_when_standby
        self.vectors[self.cycle_number][1]["we"]  = self.we_when_standby
        self.vectors[self.cycle_number][1]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][1]["di"]  = di
        self.vectors[self.cycle_number][1]["do"]  = do

        self.vectors[self.cycle_number][2]["clk"] = "0";
        self.vectors[self.cycle_number][2]["ce"]  = self.ce_when_standby
        self.vectors[self.cycle_number][2]["we"]  = self.we_when_standby
        self.vectors[self.cycle_number][2]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][2]["di"]  = di
        self.vectors[self.cycle_number][2]["do"]  = "x" * self.bits

        self.vectors[self.cycle_number][3]["clk"] = "0";
        self.vectors[self.cycle_number][3]["ce"]  = self.ce_when_standby
        self.vectors[self.cycle_number][3]["we"]  = self.we_when_standby
        self.vectors[self.cycle_number][3]["adr"] = format(word,'0' + str(self.adr_width)+'b')
        self.vectors[self.cycle_number][3]["di"]  = di
        self.vectors[self.cycle_number][3]["do"]  = "x" * self.bits

        # increase the cycle_number
        if (("increase_cycle" in arg) and (arg['increase_cycle'] == 0)) :
            pass
        else :
            self.cycle_number += 1

    def comment (self,*arg) :
        if (len(self.vectors)==self.cycle_number) :
            self.vectors.append([])

        if (len(self.vectors[self.cycle_number])==0) :
            # no operation yet, no comment yet
            self.vectors[self.cycle_number]=[{},{},{},{}]
            self.vectors[self.cycle_number].append(';' + ''.join(arg))
        elif (len(self.vectors[self.cycle_number])==4) :
            # has operation already , no comment yet
            self.vectors[self.cycle_number].append(';' + ''.join(arg))
        else :
            # has operation already , has comment already
            self.vectors[self.cycle_number][4] += "\n"
            self.vectors[self.cycle_number][4] += ';' + ''.join(arg)

    def write_vec(self,filename="spram_func.vec"):
        output_width={}
        output_width['time'] = 8 + len(str(self.cycle_number * self.cycle_time))
        output_width['clk']  = 0 + len(self.clkname)
        output_width['ce']   = 0 + len(self.cename)
        output_width['we']   = 0 + len(self.wename)
        output_width['adr']  = max(self.adr_width, 4 + len(self.adrname) + len(str(self.adr_width-1)))
        output_width['di']   = max(self.bits   ,   4 + len(self.diname) + len(str(self.bits-1)))
        output_width['do']   = max(self.bits   ,   4 + len(self.doname) + len(str(self.bits-1)))

        output_format1 = \
                '{name:<' + str(output_width['time']) + 's}' \
                ' {clk:<' + str(output_width['clk'])  + 's}' \
                ' {ce:<'  + str(output_width['ce'])   + 's}' \
                ' {we:<'  + str(output_width['we'])   + 's}' \
                ' {adr:<' + str(output_width['adr'])  + 's}' \
                ' {di:<'  + str(output_width['di'])   + 's}' \
                ' {do:<'  + str(output_width['do'])   + 's}\n' 

        output_format2 = \
                '{time:>' + str(output_width['time']) + '.2f}' \
                ' {clk:<' + str(output_width['clk'])  + 's}' \
                ' {ce:<'  + str(output_width['ce'])   + 's}' \
                ' {we:<'  + str(output_width['we'])   + 's}' \
                ' {adr:<' + str(output_width['adr'])  + 's}' \
                ' {di:<'  + str(output_width['di'])   + 's}' \
                ' {do:<'  + str(output_width['do'])   + 's}\n' 

        with open(filename,"w") as f :
            f.write("; vector file for memory {}x{}\n;\n".format(self.words,self.bits))
            f.write("; for finesim tool, use following to include vector file\n")
            f.write(";   .option finesim_vector = {}\n".format(filename))
            f.write(";   .option finesim_vector_mode = 1|0 $ 1 for A[0], A[1] likewise bus name \n")
            f.write(";                                     $ 0 for A0, A1 likewise bus name\n;\n")
            f.write("; for xa tool, use following to include vector file\n")
            f.write(';   .option XA_CMD="load_vector_file -file {}\n'.format(filename))
            f.write(';   .option XA_CMD="set_vector_option -vec_mode hsim|xa" $ hsim for A[0], A[1] likewise bus name \n')
            f.write(";                                                        $ xa for A0, A1 likewise bus name\n")
            f.write(";   change 'tdelay {cycle_time} mask_do'_do to 'tdelay {cycle_time} mask_by_name=mask_do'\n;\n".format(cycle_time   = self.cycle_time))
            f.write("; please change tunit according to your simulation\n")
            f.write("; please define slope/vh param in your sim file\n\n")

            f.write("tunit 1ns\n")
            f.write("slope slope\n")
            f.write("vih   vh\n")
            f.write("vil   0\n")
            f.write("voh  'vh*0.9'\n")
            f.write("vol  'vh*0.1'\n\n")

            f.write(";mask mask_do {do}\n".format(do   = self.doname  + '[0:' + str(self.bits-1) + "]"))
            f.write(";tdelay {cycle_time} mask_do\n\n".format(cycle_time   = self.cycle_time))
            f.write(output_format1.format(\
                    name = "io", \
                    clk  = "i", \
                    ce   = "i", \
                    we   = "i", \
                    adr  = "i", \
                    di   = "i", \
                    do   = "o"))

            f.write(output_format1.format(\
                    name = "radix", \
                    clk  = "1", \
                    ce   = "1", \
                    we   = "1", \
                    adr  = "1" * self.adr_width, \
                    di   = "1" * self.bits, \
                    do   = "1" * self.bits))

            f.write(output_format1.format(\
                    name = "vname", \
                    clk  = self.clkname, \
                    ce   = self.cename, \
                    we   = self.wename, \
                    adr  = self.adrname + '[' + str(self.adr_width-1) + ":0]", \
                    di   = self.diname  + '[0:' + str(self.bits-1) + "]", \
                    do   = self.doname  + '[0:' + str(self.bits-1) + "]"))

            f.write(output_format1.format(\
                    name = "tdelay " + str(self.cycle_time) + " ", \
                    clk  = "0", \
                    ce   = "0", \
                    we   = "0", \
                    adr  = "0" * self.adr_width, \
                    di   = "0" * self.bits, \
                    do   = "1" * self.bits))

            f.write("\n")

            for i in range(self.cycle_number) :
                if (len(self.vectors[i]) == 5) :
                    # print the comment
                    f.write(self.vectors[i][4])
                    f.write("\n")

                # print the vector
                for j in range(4) :
                    if (len(self.vectors[i][j]) == 0) :
                        # no operation for this cycle
                        break

                    f.write(output_format2.format(\
                            time = (i + j/4) * self.cycle_time, \
                            clk  = self.vectors[i][j]["clk"], \
                            ce   = self.vectors[i][j]["ce"], \
                            we   = self.vectors[i][j]["we"], \
                            adr  = self.vectors[i][j]["adr"], \
                            di   = self.vectors[i][j]["di"], \
                            do   = self.vectors[i][j]["do"]))

                    f.close


